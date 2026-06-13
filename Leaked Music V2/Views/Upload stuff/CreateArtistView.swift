//
//  CreateArtistView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/13/25.
//


import SwiftUI

struct CreateArtistView: View {
    @ObservedObject var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss

    @State private var artistName: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Artist Information")) {
                    TextField("Artist Name", text: $artistName)
                }

                Section(header: Text("Artist Image (Optional)")) {
                    HStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    Text("No Image")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                )
                        }
                        Button("Select Image") {
                            showImagePicker = true
                        }
                    }
                }
            }
            .navigationTitle("Create New Artist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.createNewArtist(artistName: artistName, artistImage: selectedImage) { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(artistName.isEmpty || viewModel.isUploading)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .overlay(
                viewModel.isUploading ? ProgressView("Creating Artist...") : nil
            )
        }
    }
}
