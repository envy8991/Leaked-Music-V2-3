import SwiftUI

struct AlbumRow: View {
    var album: Album

    var body: some View {
        HStack(spacing: 12) {
            // Album cover image with CachedAsyncImage
            CachedAsyncImage(
                url: URL(string: album.coverURL),
                fallback: AnyView(
                    ZStack {
                        Color.gray.opacity(0.3)
                        Text("No Cover")
                            .foregroundColor(.white)
                    }
                    .cornerRadius(8)
                    .frame(width: 80, height: 80)
                )
            )
            .frame(width: 80, height: 80)
            .clipped()
            .cornerRadius(8)
            .accessibilityLabel(Text("\(album.title) cover art"))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(album.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(album.artist)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding(12)
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
        )
        .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
        .padding(.vertical, 4)
        .padding(.horizontal, 16)
    }
}
