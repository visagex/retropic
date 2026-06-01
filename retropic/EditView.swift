//
//  EditView.swift
//  retropic
//
//  Created by Kolby De Aguiar on 5/26/26.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Options

enum ResolutionOption: String, CaseIterable {
    case original = "Original"
    case w124 = "124px"
    case w32  = "32px"
    case w16  = "16px"

    // Returns the target size maintaining the original aspect ratio.
    // Never upscales — if the image is already smaller, the original size is returned.
    func targetSize(for original: CGSize) -> CGSize {
        let targetWidth: CGFloat
        switch self {
        case .original: return original
        case .w124: targetWidth = 124
        case .w32:  targetWidth = 32
        case .w16:  targetWidth = 16
        }
        guard original.width > targetWidth else { return original }
        let scale = targetWidth / original.width
        return CGSize(width: targetWidth, height: (original.height * scale).rounded())
    }
}

enum Palette: String, CaseIterable {
    case original = "Original"
    case grayscale = "Gray"
    case sepia     = "Sepia"
    case gameBoy   = "Game Boy"
    case neon      = "Neon"
    case noir      = "Noir"
}

// MARK: - View

struct EditView: View {
    let originalImage: UIImage

    @State private var resolution: ResolutionOption = .original
    @State private var palette: Palette = .original
    @State private var blurAmount: Double = 0
    @State private var processedImage: UIImage? = nil
    @State private var processingTask: Task<Void, Never>? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // MARK: Preview
                Image(uiImage: processedImage ?? originalImage)
                    .resizable()
                    // .none keeps pixels sharp when the image is tiny — gives the retro pixelated look
                    .interpolation(resolution == .original ? .medium : .none)
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .padding(.horizontal)

                // MARK: Controls
                VStack(spacing: 20) {

                    // Resolution
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Resolution")
                            .font(.headline)
                        Picker("Resolution", selection: $resolution) {
                            ForEach(ResolutionOption.allCases, id: \.self) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Palette
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color Palette")
                            .font(.headline)
                        Picker("Palette", selection: $palette) {
                            ForEach(Palette.allCases, id: \.self) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    // Blur
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Blur: \(blurAmount, specifier: "%.1f")")
                            .font(.headline)
                        Slider(value: $blurAmount, in: 0...2, step: 0.1)
                    }
                }
                .padding(.horizontal)

                // MARK: Save
                Button("Save to Photos") {
                    saveToPhotos()
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
            }
        }
        .navigationTitle("Edit")
        .navigationBarTitleDisplayMode(.inline)
        // initial: true means this also fires once on appear, replacing the need for .onAppear
        .onChange(of: resolution, initial: true) { _, _ in scheduleProcess() }
        .onChange(of: palette) { _, _ in scheduleProcess() }
        .onChange(of: blurAmount) { _, _ in scheduleProcess() }
        .onDisappear { processingTask?.cancel() }
    }

    // MARK: - Scheduling

    // Cancels any in-flight work before starting a new process so rapid
    // slider drags don't stack up a queue of heavy operations.
    private func scheduleProcess() {
        processingTask?.cancel()
        processingTask = Task {
            // Capture current values as local copies before leaving the main actor
            let (img, res, pal, blur) = (originalImage, resolution, palette, blurAmount)
            // Do the heavy work on a background thread
            let result = await Task.detached(priority: .userInitiated) {
                Self.buildImage(from: img, resolution: res, palette: pal, blur: blur)
            }.value
            guard !Task.isCancelled else { return }
            processedImage = result
        }
    }

    // MARK: - Image pipeline (static so it can be called from a detached Task)

    private static func buildImage(
        from original: UIImage,
        resolution: ResolutionOption,
        palette: Palette,
        blur: Double
    ) -> UIImage {
        // Step 1 — downscale with UIGraphicsImageRenderer (CPU, very fast)
        let targetSize = resolution.targetSize(for: original.size)
        let small: UIImage
        if targetSize == original.size {
            small = original
        } else {
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            small = renderer.image { _ in
                original.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }

        // Step 2 — convert to CIImage for filter pipeline
        guard var ci = CIImage(image: small) else { return small }
        let originalExtent = ci.extent

        // Step 3 — blur (applied before color so blurred edges pick up the palette too)
        if blur > 0 {
            let f = CIFilter.gaussianBlur()
            f.inputImage = ci
            f.radius = Float(blur)
            // Gaussian blur expands the image bounds slightly; crop back to original size
            if let out = f.outputImage {
                ci = out.cropped(to: originalExtent)
            }
        }

        // Step 4 — color palette
        ci = applyPalette(palette, to: ci)

        // Step 5 — render back to UIImage
        let ctx = CIContext()
        guard let cg = ctx.createCGImage(ci, from: ci.extent) else { return small }
        return UIImage(cgImage: cg)
    }

    private static func applyPalette(_ palette: Palette, to image: CIImage) -> CIImage {
        switch palette {

        case .original:
            return image

        case .grayscale:
            let f = CIFilter.photoEffectMono()
            f.inputImage = image
            return f.outputImage ?? image

        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = image
            f.intensity = 0.9
            return f.outputImage ?? image

        case .gameBoy:
            // Desaturate → posterize to 4 levels → tint green
            let mono = CIFilter.photoEffectMono()
            mono.inputImage = image

            let post = CIFilter.colorPosterize()
            post.inputImage = mono.outputImage ?? image
            post.levels = 4

            let tint = CIFilter.colorMonochrome()
            tint.inputImage = post.outputImage ?? image
            tint.color = CIColor(red: 0.61, green: 0.73, blue: 0.06) // classic Game Boy green
            tint.intensity = 1.0
            return tint.outputImage ?? image

        case .neon:
            // Crank saturation and contrast, then posterize for a flat neon look
            let ctrl = CIFilter.colorControls()
            ctrl.inputImage = image
            ctrl.saturation = 3.0
            ctrl.contrast = 1.2
            ctrl.brightness = 0.05

            let post = CIFilter.colorPosterize()
            post.inputImage = ctrl.outputImage ?? image
            post.levels = 8
            return post.outputImage ?? image

        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = image
            return f.outputImage ?? image
        }
    }

    // MARK: - Save

    private func saveToPhotos() {
        guard let img = processedImage else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
}

#Preview {
    NavigationStack {
        EditView(originalImage: UIImage(systemName: "photo")!)
    }
}
