import SwiftUI

struct LibraryAlbumSongRow: View {
    let song: Song
    let onPlay: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    @State private var showPlaylistPicker = false
    @ObservedObject var downloadManager = DownloadManager.shared
    @EnvironmentObject var session: SessionStore
    @ObservedObject var playerManager = AudioPlayerManager.shared

    /// Checks if the song is downloaded.
    var isDownloaded: Bool {
        downloadManager.downloadedSongs.contains { $0.id == song.id }
    }
    
    /// Determines if this song is currently playing.
    var isCurrentlyPlaying: Bool {
        playerManager.currentSong?.id == song.id
    }
    
    /// Calculates progress (0...1) based on currentTime and duration.
    var progress: Double {
        guard isCurrentlyPlaying, playerManager.duration > 0 else { return 0 }
        let prog = playerManager.currentTime / playerManager.duration
        return min(max(prog, 0), 1)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Song title
            Text(song.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(.white)
            
            // Play button: shows progress if currently playing, otherwise a standard play button
            if isCurrentlyPlaying {
                ProgressPlayButton(isPlaying: playerManager.isPlaying, progress: progress) {
                    playerManager.togglePlayPause()
                }
            } else {
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Options menu
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
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(6)
            }
            .menuStyle(BorderlessButtonMenuStyle())
        }
        .padding()
        .frame(minHeight: 70)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.black.opacity(0.6), Color.black.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
        .onChange(of: playerManager.currentTime) { _ in
            print("Song: \(song.title), isCurrentlyPlaying: \(isCurrentlyPlaying), progress: \(progress), currentTime: \(playerManager.currentTime), duration: \(playerManager.duration)")
        }
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerView(song: song)
                .environmentObject(session)
        }
    }
}
