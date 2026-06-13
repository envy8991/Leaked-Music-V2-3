import SwiftUI
import FirebaseFirestore

struct SongRow: View {
    let originalSong: Song // The original song to display
    var song: Song { originalSong }

    var showAddButton: Bool = true
    var onPlay: (() -> Void)? = nil

    @EnvironmentObject var session: SessionStore
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @ObservedObject var downloadManager = DownloadManager.shared

    @State private var isAdding: Bool = false
    @State private var addError: String?
    @State private var showPlaylistPicker = false

    var isDownloaded: Bool {
        downloadManager.downloadedSongs.contains { $0.id == song.id }
    }
    
    // Determines if this row's song is the one currently playing.
    var isCurrentlyPlaying: Bool {
        playerManager.currentSong?.id == song.id
    }
    
    // Computes playback progress (0 to 1) if this song is currently playing.
    var progress: Double {
        guard isCurrentlyPlaying, playerManager.duration > 0 else { return 0 }
        return min(max(playerManager.currentTime / playerManager.duration, 0), 1)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Artwork
            let isArtworkFileURL = URL(string: song.artworkURL ?? "")?.isFileURL ?? false
            CachedAsyncImage(
                url: URL(string: song.artworkURL ?? ""),
                isFileURL: isArtworkFileURL,
                fallback: AnyView(
                    ZStack {
                        Color.gray.opacity(0.3)
                        Text("No Cover")
                            .foregroundColor(.white)
                    }
                    .cornerRadius(8)
                    .frame(width: 60, height: 60)
                )
            )
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            .padding(.leading, 5)

            // Song title and artist
            VStack(alignment: .leading, spacing: 4) {
                Text(song.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            // Action buttons
            HStack(spacing: -2) {
                // Play button: if this song is currently playing, use the progress play button.
                if isCurrentlyPlaying {
                    ProgressPlayButton(isPlaying: playerManager.isPlaying, progress: progress) {
                        // Toggle play/pause for the current song.
                        if playerManager.isPlaying {
                            playerManager.pause()
                        } else {
                            playerManager.resume()
                        }
                    }
                } else {
                    Button(action: {
                        if let customOnPlay = onPlay {
                            customOnPlay()
                        } else {
                            playerManager.play(song: song)
                        }
                    }) {
                        Image(systemName: "play.circle.fill")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Add-to-library button (if needed)
                if showAddButton,
                   let songID = song.id,
                   !session.librarySongIDs.contains(songID) {
                    Button(action: {
                        isAdding = true
                        session.addSongToLibrary(originalSong) { error in
                            isAdding = false
                            if let error = error {
                                addError = error.localizedDescription
                            }
                        }
                    }) {
                        if isAdding {
                            ProgressView().frame(width: 40, height: 40)
                        } else {
                            Image(systemName: "plus.circle")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isAdding)
                }
                
                // Show Album (if applicable)
                if let albumId = song.albumId,
                   let albumTitle = song.albumTitle,
                   let albumArtist = song.albumArtist,
                   let coverURL = song.artworkURL {
                    NavigationLink(
                        destination: AlbumDetailView(
                            album: Album(
                                id: albumId,
                                title: albumTitle,
                                artist: albumArtist,
                                coverURL: coverURL,
                                uploadedAt: nil
                            )
                        )
                    ) {
                        Image(systemName: "rectangle.stack")
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                    }
                }
                
                // Menu for additional actions
                Menu {
                    Button("Play Next") {
                        AudioPlayerManager.shared.insertSongNext(song)
                    }
                    Button("Add to Playlist") {
                        showPlaylistPicker = true
                    }
                    if isDownloaded {
                        Button("Remove Download") {
                            DownloadManager.shared.removeDownloadedSong(song: song)
                        }
                    } else {
                        Button("Download") {
                            DownloadManager.shared.downloadSong(song: song) { result in
                                switch result {
                                case .success(let downloadedSong):
                                    print("\(downloadedSong.title) downloaded successfully.")
                                case .failure(let error):
                                    print("Download failed: \(error.localizedDescription)")
                                }
                            }
                        }
                    }
                    Button("Delete", role: .destructive) {
                        deleteSong()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .padding(6)
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
            .frame(alignment: .trailing)
            .padding(.trailing, 8)
        }
        .padding(.vertical)
        .frame(minHeight: 90)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
        .alert(item: Binding(
            get: { addError.map { AppError(message: $0) } },
            set: { _ in addError = nil }
        )) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerView(song: song)
                .environmentObject(session)
        }
    }
    
    // Direct deletion logic inside SongRow.
    private func deleteSong() {
        guard let songId = song.id,
              let uid = session.currentUser?.uid,
              !uid.isEmpty else { return }
        let db = Firestore.firestore()
        db.collection("users")
            .document(uid)
            .collection("librarySongs")
            .document(songId)
            .delete { error in
                if let error = error {
                    addError = error.localizedDescription
                } else {
                    // Optionally, update the session's librarySongIDs set.
                    session.librarySongIDs.remove(songId)
                    // You might also want to notify a parent view to update its song list,
                    // depending on your UI architecture.
                }
            }
    }
}
