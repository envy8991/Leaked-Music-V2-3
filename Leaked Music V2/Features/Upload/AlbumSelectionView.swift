import SwiftUI

struct AlbumSelectionView: View {
    @ObservedObject var viewModel: UploadViewModel
    let selectedArtist: Artist

    var body: some View {
        List {
            Section(header: Text("Albums by \(selectedArtist.name)")) {
                ForEach(viewModel.albumsForSelectedArtist, id: \.id) { album in
                    NavigationLink(value: album) {
                        Text(album.title)
                    }
                }
                Button("Create New Album for \(selectedArtist.name)") {
                    viewModel.showCreateAlbumSheet = true
                }
            }
        }
        .navigationDestination(for: Album.self) { album in
            SongUploadView(viewModel: viewModel, selectedArtist: selectedArtist, selectedAlbum: album)
        }
        .sheet(isPresented: $viewModel.showCreateAlbumSheet) {
            CreateAlbumView(viewModel: viewModel, selectedArtist: selectedArtist)
        }
        .onAppear {
            // Store the selected artist and start listening to album changes
            viewModel.selectedArtist = selectedArtist
            viewModel.listenToAlbumsForArtist(selectedArtist)
        }
    }
}
