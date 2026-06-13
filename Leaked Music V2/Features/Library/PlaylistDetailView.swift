import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PlaylistDetailView: View {
    let playlist: Playlist

    @State private var songs: [Song] = []
    @State private var isLoading = true
    @State private var errorMessage: AppError? = nil

    @EnvironmentObject var session: SessionStore
    private let playerManager = AudioPlayerManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Playlist header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(playlist.name)
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)

                    // "Play All" Button
                    if !isLoading && !songs.isEmpty {
                        HStack {
                            Spacer()
                            Button(action: playAll) {
                                HStack {
                                    Image(systemName: "play.fill")
                                    Text("Play All")
                                        .fontWeight(.bold)
                                }
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }

                    if isLoading {
                        ProgressView("Loading playlist songs...")
                            .padding()
                    } else if songs.isEmpty {
                        Text("No songs found for this playlist.")
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                    } else {
                        ForEach(songs, id: \.id) { song in
                            SongRow(
                                originalSong: song,
                                onPlay: { playSong(song) }
                            )
                            .environmentObject(session)
                        }
                    }
                }
                .padding(.top)
            }
        }
        .navigationTitle("Playlist Detail")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $errorMessage) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: loadPlaylistSongs)
    }

    private func loadPlaylistSongs() {
        guard !playlist.songIDs.isEmpty else {
            isLoading = false
            return
        }
        isLoading = true

        let db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? "" // Get current user ID

        let chunks = playlist.songIDs.chunked(into: 30)
        let group = DispatchGroup()
        var allSongs: [Song] = []
        var errors: [Error] = []

        for chunk in chunks {
            group.enter()
            var chunkSongs: [Song] = []
            var chunkErrors: [Error] = []
            let innerGroup = DispatchGroup()

            for songId in chunk {
                innerGroup.enter()
                // Try to fetch as personal song first
                db.collection("users").document(uid).collection("personalSongs").document(songId).getDocument { personalSongSnapshot, personalSongError in
                    if let personalSongError = personalSongError {
                        chunkErrors.append(personalSongError)
                        innerGroup.leave()
                        return
                    }
                    if let personalSong = try? personalSongSnapshot?.data(as: Song.self) {
                        chunkSongs.append(personalSong)
                        innerGroup.leave()
                    } else {
                        // If not a personal song, try to fetch as global song
                        db.collection("songs").document(songId).getDocument { globalSongSnapshot, globalSongError in
                            if let globalSongError = globalSongError {
                                chunkErrors.append(globalSongError)
                            } else if let globalSong = try? globalSongSnapshot?.data(as: Song.self) {
                                chunkSongs.append(globalSong)
                            }
                            innerGroup.leave()
                        }
                    }
                }
            }

            innerGroup.notify(queue: .global()) {
                allSongs.append(contentsOf: chunkSongs)
                errors.append(contentsOf: chunkErrors)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if !errors.isEmpty && allSongs.isEmpty { // Only show error if no songs are loaded
                self.errorMessage = AppError(message: "Error loading playlist songs: \(errors.first!.localizedDescription)")
            } else {
                self.songs = allSongs
                // Sort the songs based on the order in playlist.songIDs.
                self.songs.sort { s1, s2 in
                    if let i1 = playlist.songIDs.firstIndex(of: s1.id ?? ""),
                       let i2 = playlist.songIDs.firstIndex(of: s2.id ?? "") {
                        return i1 < i2
                    }
                    return false
                }
            }
            self.isLoading = false
        }
    }


    /// Play all songs from the beginning.
    private func playAll() {
        guard let firstSong = songs.first else { return }
        playerManager.play(song: firstSong, in: songs, startIndex: 0)
    }

    private func playSong(_ song: Song) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else { return }
        playerManager.play(song: song, in: songs, startIndex: index)
    }

    private func shareSong(_ song: Song) {
        print("Sharing \(song.title)")
    }
}

// Helper extension for chunking
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
