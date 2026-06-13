import SwiftUI

struct CreateAlbumView: View {
    @ObservedObject var viewModel: UploadViewModel
    let selectedArtist: Artist // Associate album with this artist
    @Environment(\.dismiss) var dismiss

    @State private var albumTitle: String = ""
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Album Information")) {
                    TextField("Album Title", text: $albumTitle)
                }

                Section(header: Text("Album Cover Art (Optional)")) {
                    HStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    Text("No Cover")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                )
                        }
                        Button("Select Cover Art") {
                            showImagePicker = true
                        }
                    }
                }
            }
            .navigationTitle("Create New Album")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.createNewAlbum(albumTitle: albumTitle, albumCover: selectedImage, artist: selectedArtist) { success in
                            if success {
                                dismiss()
                            }
                        }
                    }
                    .disabled(albumTitle.isEmpty || viewModel.isUploading)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .overlay(
                viewModel.isUploading ? ProgressView("Creating Album...") : nil
            )
        }
    }
}
