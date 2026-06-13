import SwiftUI

struct SongListView: View {
    var songs: [Song]
    var showAddButton: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            ForEach(songs) { song in
                SongRow(originalSong: song, showAddButton: showAddButton)
                    // Remove .padding(.horizontal, 16) from here
                    .padding(.vertical, 8) // Keep vertical padding
                    // No .background here anymore - it's inside SongRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.horizontal)
    }
}
