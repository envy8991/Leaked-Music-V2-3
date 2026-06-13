import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MusicKit

struct LibraryAlbumDetailView: View {
    let album: Album
    var isPersonalAlbum: Bool = false // Flag to indicate if it's a personal album

    @State private var songs: [Song] = []
    @State private var isLoading = true
    @State private var errorMessage: AppError? = nil

    @EnvironmentObject var session: SessionStore
    private let playerManager = AudioPlayerManager.shared

    @State private var isGlobalAlbumInLibrary = false // For global albums - library status

    var body: some View {
        ZStack {
            // Full-screen gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.8), Color.purple.opacity(0.8), Color.blue.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Album Cover
                    if let url = URL(string: album.coverURL), !album.coverURL.isEmpty {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 260)
                                    .frame(maxWidth: .infinity)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(16)
                                    .padding(.horizontal, 20)
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            case .failure:
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray)
                                    .frame(height: 260)
                                    .padding(.horizontal, 20)
                                    .overlay(
                                        Text("No Cover")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .animation(.easeInOut(duration: 0.4), value: album.coverURL)
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.gray)
                            .frame(height: 260)
                            .padding(.horizontal, 20)
                            .overlay(
                                Text("No Cover")
                                    .foregroundColor(.white)
                                    .font(.headline)
                            )
                    }

                    // Album Info
                    VStack(alignment: .leading, spacing: 6) {
                        Text(album.title)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .transition(.opacity)
                        Text(album.artist)
                            .font(.subheadline)
                            .foregroundColor(Color.white.opacity(0.8))
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 20)

                    // Add/Remove Button - Conditionally Shown for Global Albums
                    if !isPersonalAlbum { // Only show for global albums
                        Button(action: toggleAlbumLibrary) {
                            HStack {
                                Spacer()
                                Image(systemName: isGlobalAlbumInLibrary ? "checkmark.circle.fill" : "plus.circle")
                                Text(isGlobalAlbumInLibrary ? "Remove Album" : "Add Album")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: isGlobalAlbumInLibrary
                                                       ? [Color.red.opacity(0.8), Color.red]
                                                       : [Color.green.opacity(0.8), Color.green]),
                                    startPoint: .leading,
                                    endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .animation(.easeInOut(duration: 0.3), value: isGlobalAlbumInLibrary)
                    }

                    // Song List Section
                    if isLoading {
                        ProgressView("Loading Songs...")
                            .padding()
                            .transition(.opacity)
                    } else if songs.isEmpty {
                        Text("No songs found for this album.")
                            .foregroundColor(Color.white.opacity(0.8))
                            .padding()
                            .transition(.opacity)
                    } else {
                        ForEach(songs) { song in
                            AlbumSongRow(
                                song: song,
                                isInLibrary: !isPersonalAlbum && session.librarySongIDs.contains(song.id ?? ""), // Global library check
                                onPlay: { playSong(song) },
                                onToggleLibrary: !isPersonalAlbum ? { toggleSongLibrary(song) } : {}, // Only for global songs
                                onShare: { shareSong(song) },
                                onDelete: isPersonalAlbum ? { removePersonalSong(song) } : {} // Only for personal songs
                            )
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
        .navigationTitle("Album Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $errorMessage) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK")))
        }
        .onAppear {
            withAnimation(.easeInOut) {
                if !isPersonalAlbum {
                    checkIfAlbumInLibrary()
                }
                loadSongs()
            }
        }
    }

    // MARK: - Load Songs - Now handles Personal/Global context
    private func loadSongs() {
        guard let albumId = album.id, let uid = session.currentUser?.uid else {
            isLoading = false
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        // For personal albums, query "personalSongs"; for global (library) albums, query "librarySongs" for the current user.
        let collectionPath = isPersonalAlbum ? "users/\(uid)/personalSongs" : "users/\(uid)/librarySongs"

        db.collection(collectionPath)
            .whereField("albumId", isEqualTo: albumId)
            .order(by: "title", descending: false) // Changed to "title" since "title_lower" is not stored.
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = AppError(message: "Error loading songs: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    songs = snapshot.documents.compactMap { document in
                        try? document.data(as: Song.self)
                    }
                }
                isLoading = false
            }
    }

    // MARK: - Library Methods - Global Album Library Actions
    private func checkIfAlbumInLibrary() {
        guard let uid = session.currentUser?.uid, let albumId = album.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid)
            .collection("libraryAlbums")
            .document(albumId)
            .getDocument { snapshot, _ in
                withAnimation {
                    self.isGlobalAlbumInLibrary = (snapshot?.exists ?? false)
                }
            }
    }

    private func toggleAlbumLibrary() {
        guard let albumId = album.id else { return }
        if isGlobalAlbumInLibrary {
            removeAlbumAndSongsFromLibrary(albumId: albumId)
        } else {
            addAlbumAndSongsToLibrary()
        }
    }

    private func addAlbumAndSongsToLibrary() {
        session.addAlbumToLibrary(album: album) { err in
            if let err = err {
                self.errorMessage = AppError(message: "Failed to add album: \(err.localizedDescription)")
                return
            }
            for song in songs {
                session.addSongToLibrary(song) { songErr in
                    if let songErr = songErr {
                        print("Failed to add song \(song.title): \(songErr.localizedDescription)")
                    }
                }
            }
            withAnimation {
                self.isGlobalAlbumInLibrary = true
            }
        }
    }

    private func removeAlbumAndSongsFromLibrary(albumId: String) {
        removeAlbumFromLibrary(albumId: albumId)
        for song in songs {
            if session.librarySongIDs.contains(song.id ?? "") {
                removeSongFromLibrary(song)
            }
        }
    }

    private func removeAlbumFromLibrary(albumId: String) {
        guard let uid = session.currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid)
            .collection("libraryAlbums")
            .document(albumId)
            .delete { err in
                if let err = err {
                    self.errorMessage = AppError(message: "Failed to remove album: \(err.localizedDescription)")
                } else {
                    withAnimation {
                        self.isGlobalAlbumInLibrary = false
                    }
                }
            }
    }

    private func toggleSongLibrary(_ song: Song) {
        if session.librarySongIDs.contains(song.id ?? "") {
            removeSongFromLibrary(song)
        } else {
            addSongToLibrary(song)
        }
    }

    private func addSongToLibrary(_ song: Song) {
        session.addSongToLibrary(song) { err in
            if let err = err {
                self.errorMessage = AppError(message: "Failed to add song: \(err.localizedDescription)")
            }
        }
    }

    private func removeSongFromLibrary(_ song: Song) {
        guard let uid = session.currentUser?.uid, let songId = song.id else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid)
            .collection("librarySongs")
            .document(songId)
            .delete { err in
                if let err = err {
                    self.errorMessage = AppError(message: "Failed to remove song: \(err.localizedDescription)")
                }
            }
    }

    // MARK: - Personal Song Removal
    private func removePersonalSong(_ song: Song) {
        guard let uid = session.currentUser?.uid, let songId = song.id else { return }
        session.deletePersonalSong(songId: songId) { error in
            if let error = error {
                self.errorMessage = AppError(message: "Failed to remove personal song: \(error.localizedDescription)")
            } else {
                songs.removeAll { $0.id == songId }
            }
        }
    }

    // MARK: - Playback & Share
    private func playSong(_ song: Song) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else { return }
        playerManager.play(song: song, in: songs, startIndex: index)
    }

    private func shareSong(_ song: Song) {
        print("Sharing \(song.title)")
    }
}
