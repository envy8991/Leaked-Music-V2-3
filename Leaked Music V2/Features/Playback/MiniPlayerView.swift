import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject var playerManager: AudioPlayerManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showFullPlayer = false
    @GestureState private var dragOffset = CGSize.zero

    init(playerManager: AudioPlayerManager = .shared) {
        self._playerManager = ObservedObject(wrappedValue: playerManager)
    }

    var body: some View {
        if let song = playerManager.currentSong {
            VStack(spacing: 0) {
                ProgressView(value: playerManager.currentTime, total: max(playerManager.duration, 1))
                    .tint(themeManager.currentTheme.primaryColor)
                    .scaleEffect(x: 1, y: 0.7, anchor: .center)

                HStack(spacing: 12) {
                    CachedAsyncImage(
                        url: URL(string: song.artworkURL ?? ""),
                        fallback: AnyView(
                            Image(systemName: "music.note")
                                .font(.title2)
                                .foregroundColor(themeManager.currentTheme.primaryColor)
                        )
                    )
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.18), radius: 6, y: 3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.title)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                            .lineLimit(1)
                        Text(song.artist)
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.68))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    HStack(spacing: 14) {
                        Button(action: { playerManager.skipBackward() }) {
                            Image(systemName: "gobackward.15")
                        }
                        Button(action: playerManager.togglePlayPause) {
                            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3.bold())
                                .frame(width: 36, height: 36)
                                .background(themeManager.currentTheme.primaryColor)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        Button(action: { playerManager.skipForward() }) {
                            Image(systemName: "goforward.15")
                        }
                    }
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.primaryColor)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
                .onTapGesture { showFullPlayer = true }
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            if value.translation.height < -50 { showFullPlayer = true }
                        }
                )
            }
            .background(miniPlayerBackground)
            .clipShape(RoundedRectangle(cornerRadius: themeManager.currentTheme.isGlassStyle ? 24 : 0, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 12, y: -4)
            .fullScreenCover(isPresented: $showFullPlayer) {
                FullPlayerView(playerManager: playerManager)
                    .environmentObject(themeManager)
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var miniPlayerBackground: some View {
        if themeManager.currentTheme.isGlassStyle {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(themeManager.currentTheme.surfaceColor)
        } else {
            Color(UIColor.systemBackground)
        }
    }
}
