import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LibraryArtistDetailView: View {
    let artistName: String
    
    @State private var albums: [Album] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            List {
                if isLoading {
                    ProgressView("Loading Albums...")
                        .foregroundColor(.white)
                } else if albums.isEmpty {
                    Text("No albums found for this artist.")
                        .foregroundColor(.white)
                } else {
                    ForEach(albums) { album in
                        NavigationLink(destination: LibraryAlbumDetailView(album: album)) {
                            AlbumRow(album: album)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle(artistName)
        .alert(item: $localError) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: loadAlbumsForArtist)
    }
    
    private func loadAlbumsForArtist() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users")
            .document(uid)
            .collection("libraryAlbums")
            .whereField("artist", isEqualTo: artistName)
            .getDocuments { snapshot, err in
                if let err = err {
                    localError = AppError(message: "Error loading albums for \(artistName): \(err.localizedDescription)")
                    isLoading = false
                    return
                }
                let albumRefs = snapshot?.documents.compactMap { try? $0.data(as: LibraryAlbumRef.self) } ?? []
                loadGlobalAlbums(for: albumRefs)
            }
    }
    
    private func loadGlobalAlbums(for refs: [LibraryAlbumRef]) {
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var fetchedAlbums: [Album] = []
        for ref in refs {
            group.enter()
            db.collection("albums").document(ref.albumId).getDocument { docSnap, error in
                defer { group.leave() }
                if let docSnap = docSnap, docSnap.exists,
                   let album = try? docSnap.data(as: Album.self) {
                    fetchedAlbums.append(album)
                }
            }
        }
        group.notify(queue: .main) {
            albums = fetchedAlbums.sorted { $0.title < $1.title }
            isLoading = false
        }
    }
}
