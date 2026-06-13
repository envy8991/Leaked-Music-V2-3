import SwiftUI
import FirebaseFirestore

struct AlbumListView: View {
    var albums: [Album]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        VStack(spacing: 8) {
                            // Album Cover with CachedAsyncImage
                            if let url = URL(string: album.coverURL),
                               !album.coverURL.isEmpty {
                                
                                // Use your custom CachedAsyncImage
                                CachedAsyncImage(
                                    url: url,
                                    fallback: AnyView(placeholder.frame(width: 110, height: 110))
                                )
                                .frame(width: 110, height: 110)
                                .clipped()
                                .cornerRadius(12)
                                
                            } else {
                                placeholder
                            }
                            
                            // Album Title
                            Text(album.title)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
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
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // Same placeholder
    private var placeholder: some View {
        Rectangle()
            .fill(Color(.systemGray4))
            .frame(width: 110, height: 110)
            .cornerRadius(12)
            .overlay(
                Text("No Cover")
                    .foregroundColor(.white)
                    .font(.caption)
            )
    }
}
