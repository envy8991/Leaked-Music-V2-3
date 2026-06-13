import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct AlbumManageView: View {
    @State var album: Album
    let artist: Artist
    
    // Explicit initializer
    init(album: Album, artist: Artist) {
        self._album = State(initialValue: album)
        self.artist = artist
    }
    
    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil
    @State private var isEditingAlbum = false
    @State private var updatedAlbumTitle: String = ""
    @State private var updatedAlbumCover: UIImage? = nil
    @State private var showImagePicker = false

    var body: some View {
        Form {
            Section(header: Text("Album Details")) {
                if isEditingAlbum {
                    TextField("Album Title", text: $updatedAlbumTitle)
                    HStack {
                        if !album.coverURL.isEmpty, let url = URL(string: album.coverURL) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                            } placeholder: {
                                ProgressView()
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                        }
                        Button("Change Cover") {
                            showImagePicker = true
                        }
                    }
                    Button("Save Album Changes") {
                        updateAlbum()
                    }
                } else {
                    Text(album.title)
                    if !album.coverURL.isEmpty, let url = URL(string: album.coverURL) {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                }
                Button(isEditingAlbum ? "Cancel Editing" : "Edit Album") {
                    if isEditingAlbum {
                        isEditingAlbum = false
                    } else {
                        updatedAlbumTitle = album.title
                        isEditingAlbum = true
                    }
                }
            }
            Section(header: Text("Songs")) {
                if isLoading {
                    ProgressView("Loading songs...")
                } else {
                    ForEach(songs) { song in
                        NavigationLink(destination: SongEditView(song: song, album: album)) {
                            Text(song.title)
                        }
                    }
                    .onDelete(perform: deleteSong)
                }
            }
        }
        .navigationTitle("Manage Album")
        .onAppear(perform: loadSongs)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $updatedAlbumCover)
        }
        .alert(item: $localError) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func loadSongs() {
        isLoading = true
        let db = Firestore.firestore()
        guard let albumId = album.id else {
            localError = AppError(message: "Album id is missing")
            isLoading = false
            return
        }
        db.collection("songs")
            .whereField("albumId", isEqualTo: albumId)
            .order(by: "title_lower")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    localError = AppError(message: "Error loading songs: \(error.localizedDescription)")
                    return
                }
                songs = snapshot?.documents.compactMap { try? $0.data(as: Song.self) } ?? []
            }
    }

    private func updateAlbum() {
        guard let albumId = album.id else { return }
        let db = Firestore.firestore()
        var data: [String: Any] = [
            "title": updatedAlbumTitle,
            "title_lower": updatedAlbumTitle.lowercased()
        ]
        if let updatedCover = updatedAlbumCover {
            uploadAlbumCover(updatedCover) { coverURL in
                if let coverURL = coverURL {
                    data["coverURL"] = coverURL
                }
                db.collection("albums").document(albumId).updateData(data) { error in
                    if let error = error {
                        localError = AppError(message: "Error updating album: \(error.localizedDescription)")
                    } else {
                        album.title = updatedAlbumTitle
                        if let coverURL = data["coverURL"] as? String {
                            album.coverURL = coverURL
                        }
                        isEditingAlbum = false
                    }
                }
            }
        } else {
            db.collection("albums").document(albumId).updateData(data) { error in
                if let error = error {
                    localError = AppError(message: "Error updating album: \(error.localizedDescription)")
                } else {
                    album.title = updatedAlbumTitle
                    isEditingAlbum = false
                }
            }
        }
    }

    private func uploadAlbumCover(_ image: UIImage, completion: @escaping (String?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        let storageRef = Storage.storage().reference()
        let coverRef = storageRef.child("coverArt/\(UUID().uuidString).jpg")
        coverRef.putData(data, metadata: nil) { _, error in
            if let error = error {
                localError = AppError(message: "Error uploading album cover: \(error.localizedDescription)")
                completion(nil)
                return
            }
            coverRef.downloadURL { url, error in
                if let url = url {
                    completion(url.absoluteString)
                } else {
                    completion(nil)
                }
            }
        }
    }

    private func deleteSong(at offsets: IndexSet) {
        let db = Firestore.firestore()
        offsets.forEach { index in
            let song = songs[index]
            guard let songId = song.id else { return }
            db.collection("songs").document(songId).delete { error in
                if let error = error {
                    localError = AppError(message: "Error deleting song: \(error.localizedDescription)")
                } else {
                    songs.remove(at: index)
                }
            }
        }
    }
}
