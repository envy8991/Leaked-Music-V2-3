import SwiftUI

struct QueueView: View {
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @State private var showHistory = false

    // MARK: - Computed Properties

    /// Songs that have already played (i.e. before the current song)
    private var recentlyPlayed: [Song] {
        if playerManager.currentIndex > 0 {
            return Array(playerManager.playlist[..<playerManager.currentIndex])
        } else {
            return []
        }
    }

    /// Songs coming after the current song
    private var upNext: [Song] {
        let nextIndex = playerManager.currentIndex + 1
        if nextIndex < playerManager.playlist.count {
            return Array(playerManager.playlist[nextIndex...])
        } else {
            return []
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                // Recently Played (History) Section
                if showHistory {
                    Section(header: headerView(
                        imageName: "arrow.down.circle",
                        title: "Recently Played",
                        showHideButton: true)
                    ) {
                        if recentlyPlayed.isEmpty {
                            emptyStateView(imageName: "clock", message: "No recently played songs.")
                        } else {
                            ForEach(recentlyPlayed, id: \.id) { song in
                                QueueCellView(song: song, isCurrent: false)
                            }
                        }
                    }
                } else {
                    // When history is hidden, show a minimal prompt.
                    Section {
                        Text("Pull down to reveal history")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                // Up Next Section
                Section(header: headerView(
                    imageName: "arrow.up.circle",
                    title: "Up Next",
                    showHideButton: false)
                ) {
                    if upNext.isEmpty {
                        emptyStateView(imageName: "music.note.list", message: "Queue empty. Add songs to play next.")
                    } else {
                        ForEach(Array(upNext.enumerated()), id: \.element.id) { (index, song) in
                            QueueCellView(song: song, isCurrent: false, removeAction: {
                                withAnimation {
                                    removeFromUpNext(song)
                                }
                            })
                        }
                        .onMove(perform: moveUpNext)
                        .onDelete(perform: deleteUpNext)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Playback Queue")
            .toolbar { EditButton() }
            .refreshable {
                // When the user pulls down, reveal the history section.
                withAnimation {
                    showHistory = true
                }
            }
            .animation(.default, value: playerManager.playlist)
        }
    }

    // MARK: - Helper Views

    /// Creates a section header with an icon and (optionally) a hide button for the history section.
    private func headerView(imageName: String, title: String, showHideButton: Bool) -> some View {
        HStack {
            Image(systemName: imageName)
            Text(title)
            if showHideButton {
                Spacer()
                Button(action: {
                    withAnimation {
                        showHistory = false
                    }
                }) {
                    Text("Hide")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .font(.headline)
    }
    
    /// A view to show when a section is empty.
    private func emptyStateView(imageName: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: imageName)
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                Text(message)
                    .foregroundColor(.gray)
                    .font(.caption)
            }
            Spacer()
        }
        .padding()
    }

    // MARK: - Up Next Section Actions

    /// Removes a song from the “Up Next” portion of the playlist.
    private func removeFromUpNext(_ song: Song) {
        guard let indexInPlaylist = playerManager.playlist.firstIndex(where: { $0.id == song.id }) else { return }
        playerManager.playlist.remove(at: indexInPlaylist)
        if indexInPlaylist < playerManager.currentIndex {
            playerManager.currentIndex -= 1
        }
    }
    
    /// Called by onDelete to remove songs from “Up Next.”
    private func deleteUpNext(at offsets: IndexSet) {
        for offset in offsets {
            let song = upNext[offset]
            withAnimation {
                removeFromUpNext(song)
            }
        }
    }
    
    /// Moves songs within the “Up Next” section and rebuilds the full playlist.
    private func moveUpNext(from source: IndexSet, to destination: Int) {
        var upNextArray = upNext
        upNextArray.move(fromOffsets: source, toOffset: destination)
        let prefix = recentlyPlayed
        let current: [Song] = playerManager.currentSong.map { [$0] } ?? []
        let newPlaylist = prefix + current + upNextArray
        playerManager.playlist = newPlaylist
        playerManager.currentIndex = prefix.count
    }
}
