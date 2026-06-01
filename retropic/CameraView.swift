//
//  CameraView.swift
//  retropic
//
//  Created by Kolby De Aguiar on 5/12/26.
//

import SwiftUI
import UIKit

// MARK: - UIKit wrapper
// UIViewControllerRepresentable is SwiftUI's bridge to UIKit view controllers.
// We use it here because SwiftUI has no native camera view.
struct CameraPicker: UIViewControllerRepresentable {

    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    // The Coordinator handles callbacks from UIKit back into SwiftUI
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera       // use the live camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        // Called when the user takes a photo and taps "Use Photo"
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.isPresented = false
        }

        // Called when the user taps "Retake" / cancels
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - SwiftUI view
struct CameraView: View {
    @State private var showCamera = false
    @State private var capturedImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .padding()

                NavigationLink("Edit Photo", destination: EditView(originalImage: image))
                    .buttonStyle(.borderedProminent)
            } else {
                Text("No photo taken yet")
                    .foregroundStyle(.secondary)
            }

            Button("Open Camera") {
                showCamera = true
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Camera")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: $capturedImage, isPresented: $showCamera)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    NavigationStack {
        CameraView()
    }
}
