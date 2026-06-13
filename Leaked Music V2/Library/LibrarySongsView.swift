import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MusicKit
import OSLog

enum SongSourceType: String, CaseIterable, Identifiable {
    case personal = "Personal Songs"
    case library = "Library Songs"

    var id: String { self.rawValue }
}

struct LibrarySongsView: View {
    @EnvironmentObject var session: SessionStore

    @State private var songs: [Song] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var localError: AppError? = nil
    @State private var toastMessage: String? = nil
    @State private var lastDocument: DocumentSnapshot? = nil
    @State private var pageSize = 50
    @State private var songSource: SongSourceType = .personal // Default to Personal Songs


    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [.pink, .purple, .blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack { // Enclose content in VStack to accommodate SegmentedPicker
                Picker("Song Source", selection: $songSource) {
                    ForEach(SongSourceType.allCases) { source in
                        Text(source.rawValue).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                                .foregroundColor(.white)
                            Spacer()
                        }
                    } else {
                        ForEach(songs) { song in
                            SongRow(originalSong: song,
                                    showAddButton: false,
                                    onPlay: { playSong(song) })
                            .swipeActions {
                                Button(role: .destructive) {
                                    deleteSong(song)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }

                        if lastDocument != nil {
                            HStack {
                                Spacer()
                                if isLoadingMore {
                                    ProgressView()
                                } else {
                                    Button("Load More") {
                                        loadMoreSongs()
                                    }
                                }
                                Spacer()
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        .alert(item: $localError) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"), action: { localError = nil })
            )
        }
        .toast(message: $toastMessage)
        .onAppear {
            loadInitialSongs()
        }
        .onChange(of: songSource) { _ in // Reload songs when source changes
            loadInitialSongs()
        }
    }

    // MARK: - Initial Batch Load (Dynamic based on songSource)
    func loadInitialSongs() {
        guard let uid = session.currentUser?.uid, !uid.isEmpty else {
            Logger.log("User UID missing for library songs")
            return
        }
        isLoading = true
        songs = []
        lastDocument = nil

        let db = Firestore.firestore()
        var query: Query

        switch songSource {
        case .personal:
            query = db.collection("users").document(uid).collection("personalSongs")
                .order(by: "uploadedAt", descending: true).limit(to: pageSize)
        case .library:
            query = db.collection("users").document(uid).collection("librarySongs")
                .order(by: "uploadedAt", descending: true).limit(to: pageSize) // Or your preferred sorting for library songs
        }

        query.getDocuments { snapshot, error in
            handleSongSnapshot(snapshot: snapshot, error: error, isInitialLoad: true)
        }
    }

    // MARK: - Load More Songs (Dynamic based on songSource)
    func loadMoreSongs() {
        guard let uid = session.currentUser?.uid, !uid.isEmpty else { return }
        guard let lastDoc = lastDocument else { return }

        isLoadingMore = true

        let db = Firestore.firestore()
        var query: Query

        switch songSource {
        case .personal:
            query = db.collection("users").document(uid).collection("personalSongs")
                .order(by: "uploadedAt", descending: true).limit(to: pageSize).start(afterDocument: lastDoc)
        case .library:
            query = db.collection("users").document(uid).collection("librarySongs")
                .order(by: "uploadedAt", descending: true).limit(to: pageSize).start(afterDocument: lastDoc) // Match initial sort
        }

        query.getDocuments { snapshot, error in
            handleSongSnapshot(snapshot: snapshot, error: error, isInitialLoad: false)
        }
    }


    // MARK: - Handle Snapshot and Update UI (DRY method)
    private func handleSongSnapshot(snapshot: QuerySnapshot?, error: Error?, isInitialLoad: Bool) {
        if let error = error {
            let sourceString = songSource == .personal ? "personal" : "library"
            localError = AppError(message: "Error loading \(sourceString) songs: \(error.localizedDescription)")
            Logger.log("Error loading \(sourceString) songs", error: error)
            isLoading = false
            isLoadingMore = false
            return
        }

        guard let docs = snapshot?.documents, !docs.isEmpty else {
            lastDocument = nil // Indicate no more data for pagination
            isLoading = false
            isLoadingMore = false
            return
        }

        let fetchedSongs = docs.compactMap { try? $0.data(as: Song.self) }

        if isInitialLoad {
            self.songs = fetchedSongs
        } else {
            self.songs.append(contentsOf: fetchedSongs)
        }
        self.lastDocument = docs.last // Update last doc for pagination
        isLoading = false
        isLoadingMore = false
    }


    // MARK: - Playback
    private func playSong(_ song: Song) {
        guard let index = songs.firstIndex(where: { $0.id == song.id }) else { return }
        AudioPlayerManager.shared.play(song: song, in: songs, startIndex: index)
    }

    // MARK: - Deletion (Dynamic based on songSource)
    func deleteSong(_ song: Song) {
        guard let songId = song.id else {
            Logger.log("deleteSong: song id is nil")
            return
        }
        guard let uid = session.currentUser?.uid, !uid.isEmpty else { return }

        let db = Firestore.firestore()
        let collectionPath = songSource == .personal ? "personalSongs" : "librarySongs" // Dynamic collection path

        db.collection("users").document(uid).collection(collectionPath).document(songId)
            .delete { error in
                if let error = error {
                    let sourceString = songSource == .personal ? "personal" : "library"
                    localError = AppError(message: "Failed to delete \(sourceString) song: \(error.localizedDescription)")
                    Logger.log("Delete \(sourceString) song error", error: error)
                } else {
                    if let index = songs.firstIndex(where: { $0.id == songId }) {
                        songs.remove(at: index)
                    }
                    let sourceString = songSource == .personal ? "Personal" : "Library"
                    toastMessage = "\(sourceString) song deleted"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        toastMessage = nil
                    }
                    Logger.log("\(sourceString) song deleted: \(song.title)")
                }
            }
    }
}
