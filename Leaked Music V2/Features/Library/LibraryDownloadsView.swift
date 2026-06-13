import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage
struct LibraryDownloadsView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @ObservedObject var playerManager = AudioPlayerManager.shared

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            List {
                if downloadManager.downloadedSongs.isEmpty {
                    HStack {
                        Spacer()
                        Text("No downloads available.")
                            .foregroundColor(.white.opacity(0.8))
                            .padding()
                        Spacer()
                    }
                } else {
                    ForEach(downloadManager.downloadedSongs) { song in
                        // Use the modified SongRow
                        SongRow(originalSong: song, showAddButton: false)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Downloads")
    }
}
