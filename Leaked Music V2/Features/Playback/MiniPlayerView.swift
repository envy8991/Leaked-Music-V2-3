import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var playerManager: AudioPlayerManager
    @State private var showFullPlayer = false
    @GestureState private var dragOffset = CGSize.zero

    init(playerManager: AudioPlayerManager = .shared) {
        self._playerManager = ObservedObject(wrappedValue: playerManager)
    }

    var body: some View {
        if let song = playerManager.currentSong {
            VStack(spacing: 0) {
                Divider() // Separator line

                HStack {
                    // Display album art using CachedAsyncImage in its original shape
                    CachedAsyncImage(
                        url: URL(string: song.artworkURL ?? ""),
                        fallback: AnyView(
                            Image(systemName: "music.note")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                    )
                    .frame(width: 50, height: 50)
                    // Removed any clipping or corner rounding

                    VStack(alignment: .leading) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .padding(.leading, 8)

                    Spacer()

                    HStack(spacing: 20) {
                        Button(action: { playerManager.previous() }) {
                            Image(systemName: "backward.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        Button(action: {
                            if playerManager.isPlaying {
                                playerManager.pause()
                            } else {
                                playerManager.resume()
                            }
                        }) {
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        Button(action: { playerManager.next() }) {
                            Image(systemName: "forward.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.trailing, 8)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    showFullPlayer = true
                }
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            if value.translation.height < -50 {
                                showFullPlayer = true
                            }
                        }
                )
            }
            .background(Color(UIColor.systemBackground))
            .shadow(radius: 5)
            .fullScreenCover(isPresented: $showFullPlayer) {
                FullPlayerView(playerManager: playerManager)
            }
        } else {
            EmptyView()
        }
    }
}
