//
//  LibraryView.swift
//  retropic
//
//  Created by Kolby De Aguiar on 5/12/26.
//
import SwiftUI
import UIKit

struct LibraryPicker: UIViewControllerRepresentable {
    @Binding var showLibrary: Bool
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
            
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: LibraryPicker
        init(_ parent: LibraryPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            parent.showLibrary = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.showLibrary = false
        }
    }
}

struct LibraryView: View {
    @State private var showLibrary: Bool = false
    @State private var selectedImage: UIImage? = nil

    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(12)
                    .padding()

                NavigationLink("Edit Photo", destination: EditView(originalImage: image))
                    .buttonStyle(.borderedProminent)
            } else {
                Text("No image selected yet")
                    .foregroundStyle(.secondary)
                    .padding(.vertical)
            }

            Button("Open Library") {
                showLibrary.toggle()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showLibrary) {
            LibraryPicker(showLibrary: $showLibrary, selectedImage: $selectedImage)
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
}
