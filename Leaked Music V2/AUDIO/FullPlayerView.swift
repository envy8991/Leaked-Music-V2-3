import SwiftUI

struct FullPlayerView: View {
    @ObservedObject var playerManager: AudioPlayerManager
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var session: SessionStore

    @State private var sliderValue: Double = 0.0
    @State private var isEditingSlider = false
    @State private var showPlaylistPicker = false
    
    // Add this drag offset to track the user's swipe
    @State private var dragOffset: CGSize = .zero

    var isDownloaded: Bool {
        guard let currentSong = playerManager.currentSong else { return false }
        return DownloadManager.shared.downloadedSongs.contains { $0.id == currentSong.id }
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    // Top bar with Close button
                    HStack {
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.top)
                    .padding(.horizontal)

                    if let song = playerManager.currentSong {
                        // Larger Artwork
                        CachedAsyncImage(
                            url: URL(string: song.artworkURL ?? ""),
                            fallback: AnyView(
                                ZStack {
                                    Color.gray.opacity(0.3)
                                    Text("No Cover")
                                        .foregroundColor(.white)
                                }
                                .cornerRadius(15)
                            )
                        )
                        .id(song.id) // Force SwiftUI to reload if the song changes
                        .frame(
                            maxWidth: geometry.size.width * 0.8,
                            maxHeight: geometry.size.height * 0.5
                        )
                        .cornerRadius(15)
                        .shadow(radius: 10)

                        // Song Title and Artist
                        VStack(spacing: 5) {
                            Text(song.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text(song.artist)
                                .font(.title2)
                                .foregroundColor(Color.white.opacity(0.8))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal)

                        // Playback Slider
                        VStack {
                            Slider(
                                value: Binding(
                                    get: { isEditingSlider ? sliderValue : playerManager.currentTime },
                                    set: { sliderValue = $0 }
                                ),
                                in: 0...playerManager.duration,
                                onEditingChanged: { editing in
                                    isEditingSlider = editing
                                    if !editing {
                                        playerManager.seek(to: sliderValue)
                                    }
                                }
                            )
                            .accentColor(.white)

                            HStack {
                                Text(timeFormatted(isEditingSlider ? sliderValue : playerManager.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.white)
                                Spacer()
                                Text(timeFormatted(playerManager.duration))
                                    .font(.caption)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.horizontal)

                        // Playback Controls
                        HStack(spacing: 40) {
                            Button(action: {
                                playerManager.previous()
                            }) {
                                Image(systemName: "backward.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                if playerManager.isPlaying {
                                    playerManager.pause()
                                } else {
                                    playerManager.resume()
                                }
                            }) {
                                Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 70))
                                    .foregroundColor(.white)
                            }

                            Button(action: {
                                playerManager.next()
                            }) {
                                Image(systemName: "forward.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)

                        // Additional Options
                        HStack(spacing: 20) {
                            // Link to album, if it exists
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
                                        .font(.title)
                                        .foregroundColor(.white)
                                }
                            } else {
                                Spacer()
                            }
                            Spacer()

                            Button(action: {
                                playerManager.toggleShuffle()
                            }) {
                                Image(systemName: playerManager.isShuffleOn ? "shuffle.circle.fill" : "shuffle.circle")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            NavigationLink(destination: QueueView()) {
                                Image(systemName: "music.note.list")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            Button(action: {
                                playerManager.toggleRepeat()
                            }) {
                                Image(systemName: repeatIcon)
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                            Spacer()

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
                                    if isDownloaded {
                                        DownloadManager.shared.removeDownloadedSong(song: song)
                                    }
                                    print("Define delete logic, e.g. session.deleteSongFromLibrary")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.title)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)

                        Spacer()
                    } else {
                        Text("No song playing")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .background(Color.black.edgesIgnoringSafeArea(.all))
                .onAppear {
                    sliderValue = playerManager.currentTime
                }
                .onReceive(playerManager.$currentTime) { newTime in
                    // Keep sliderValue synced unless user is dragging
                    if !isEditingSlider {
                        sliderValue = newTime
                    }
                }
                // Hide the default navigation bar
                .navigationBarHidden(true)
                // Show playlist picker as a sheet
                .sheet(isPresented: $showPlaylistPicker) {
                    if let currentSong = playerManager.currentSong {
                        PlaylistPickerView(song: currentSong)
                            .environmentObject(session)
                    }
                }
                // 1) Offset the view by our drag amount, but only downward
                .offset(y: max(dragOffset.height, 0))
                // 2) Add a drag gesture to track downward swipes
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Only track downward pulls
                            if value.translation.height > 0 {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            // If they dragged down more than 100 points, dismiss
                            if value.translation.height > 100 {
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                // Otherwise, snap back up
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            }
        }
    }

    private func timeFormatted(_ totalSeconds: Double) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var repeatIcon: String {
        switch playerManager.repeatMode {
        case .off:
            return "repeat"
        case .one:
            return "repeat.1"
        case .all:
            return "repeat"
        }
    }
}
