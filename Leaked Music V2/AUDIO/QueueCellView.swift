import SwiftUI



// MARK: - Reusable Queue Cell View

struct QueueCellView: View {
    let song: Song
    /// Whether this song is the current song – can be used to highlight it if desired.
    let isCurrent: Bool
    /// An optional removal callback; when provided, this cell shows a swipe action to remove the song.
    var removeAction: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(
                url: URL(string: song.artworkURL ?? ""),
                fallback: AnyView(
                    ZStack {
                        Color.gray.opacity(0.3)
                        Image(systemName: "music.note")
                            .foregroundColor(.white)
                    }
                )
            )
            .frame(width: 50, height: 50)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isCurrent ? Color.blue : Color.clear, lineWidth: 2)
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(song.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        // Ensure the entire cell is tappable
        .contentShape(Rectangle())
        // Swipe-to-delete action (if a removal action is provided)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if let remove = removeAction {
                Button(role: .destructive) {
                    remove()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            }
        }
    }
}

