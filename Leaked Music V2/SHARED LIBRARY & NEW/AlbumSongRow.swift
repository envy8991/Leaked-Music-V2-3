import SwiftUI

struct AlbumSongRow: View {
    let song: Song
    let isInLibrary: Bool
    let onPlay: () -> Void
    let onToggleLibrary: () -> Void
    let onShare: () -> Void
    let onDelete: () -> Void

    @State private var showPlaylistPicker = false
    @ObservedObject var downloadManager = DownloadManager.shared
    @EnvironmentObject var session: SessionStore
    @ObservedObject var playerManager = AudioPlayerManager.shared

    var isDownloaded: Bool {
        downloadManager.downloadedSongs.contains { $0.id == song.id }
    }
    
    var isCurrentlyPlaying: Bool {
        playerManager.currentSong?.id == song.id
    }
    
    var progress: Double {
        guard isCurrentlyPlaying, playerManager.duration > 0 else { return 0 }
        return min(max(playerManager.currentTime / playerManager.duration, 0), 1)
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(song.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
            
            if isCurrentlyPlaying {
                ProgressPlayButton(isPlaying: playerManager.isPlaying, progress: progress) {
                    if playerManager.isPlaying {
                        playerManager.pause()
                    } else {
                        playerManager.resume()
                    }
                }
            } else {
                Button(action: onPlay) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: onToggleLibrary) {
                Image(systemName: isInLibrary ? "checkmark.circle.fill" : "plus.circle")
                    .font(.title2)
                    .foregroundColor(isInLibrary ? .green : .blue)
            }
            .buttonStyle(PlainButtonStyle())
            
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
                    .foregroundColor(.secondary)
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
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerView(song: song)
                .environmentObject(session)
        }
    }
}
