import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LibraryAlbumsView: View {
    @EnvironmentObject var session: SessionStore
    @State private var libraryAlbumRefs: [LibraryAlbumRef] = []
    @State private var libraryAlbums: [Album] = []
    @State private var personalAlbums: [Album] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil

    var artistName: String?

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                List {
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView("Loading...")
                                .foregroundColor(.white)
                            Spacer()
                        }
                    } else if localError != nil {
                        Section(header: Text("Error Loading Albums").foregroundColor(.red)) {
                            Text(localError!.message)
                                .foregroundColor(.white)
                        }
                        .listRowBackground(Color.clear)
                    } else if libraryAlbums.isEmpty && personalAlbums.isEmpty {
                        Text("No albums in your library.")
                            .foregroundColor(.white)
                    } else {
                        if !personalAlbums.isEmpty {
                            Section(header: Text("My Personal Albums").foregroundColor(.white)) {
                                ForEach(personalAlbums) { album in
                                    NavigationLink(destination: LibraryAlbumDetailView(album: album, isPersonalAlbum: true)) {
                                        AlbumRow(album: album)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            Task {
                                                await removePersonalAlbum(album)
                                            }
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .headerProminence(.increased)
                        }

                        if !libraryAlbums.isEmpty {
                            Section(header: Text("Library Albums").foregroundColor(.white)) {
                                ForEach(libraryAlbums) { album in
                                    NavigationLink(destination: LibraryAlbumDetailView(album: album, isPersonalAlbum: false)) {
                                        AlbumRow(album: album)
                                    }
                                    .swipeActions {
                                        Button(role: .destructive) {
                                            Task {
                                                await removeAlbum(album)
                                            }
                                        } label: {
                                            Label("Remove", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .headerProminence(.increased)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle(artistName == nil ? "Albums" : "\(artistName!) Albums")
            .navigationBarTitleDisplayMode(.large)
            .alert(item: $localError) { error in
                Alert(title: Text("Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK")))
            }
            .onAppear {
                Task {
                    await loadLibraryAlbumRefs() // Load global library album refs and albums
                    await fetchPersonalAlbums()   // Load personal albums
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    localError = nil
                }
            }
        }
    }

    private func loadLibraryAlbumRefs() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            localError = AppError(message: "No user logged in")
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        var query: Query = db.collection("users")
            .document(uid)
            .collection("libraryAlbums")
            .order(by: "dateAdded", descending: true)

        if let artistName = artistName {
            query = query.whereField("artist", isEqualTo: artistName)
        }

        do {
            let snapshot = try await query.getDocuments()
            libraryAlbumRefs = snapshot.documents.compactMap { try? $0.data(as: LibraryAlbumRef.self) }
            // Fetch global albums concurrently using the updated method.
            await loadGlobalAlbums(for: libraryAlbumRefs)
        } catch {
            localError = AppError(message: "Error loading library album refs: \(error.localizedDescription)")
            isLoading = false
        }
    }

    // Updated to use concurrent fetches
    private func loadGlobalAlbums(for refs: [LibraryAlbumRef]) async {
        let db = Firestore.firestore()
        var fetchedAlbums: [Album] = []
        
        await withTaskGroup(of: Album?.self) { group in
            for ref in refs {
                group.addTask {
                    do {
                        let document = try await db.collection("albums").document(ref.albumId).getDocument()
                        if document.exists {
                            return try? document.data(as: Album.self)
                        }
                    } catch {
                        print("Error fetching global album: \(error)")
                    }
                    return nil
                }
            }
            
            for await album in group {
                if let album = album {
                    fetchedAlbums.append(album)
                }
            }
        }
        libraryAlbums = fetchedAlbums
        isLoading = false
    }

    private func fetchPersonalAlbums() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            localError = AppError(message: "No user logged in")
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        var query: Query = db.collection("users")
            .document(uid)
            .collection("personalAlbums")
            .order(by: "uploadedAt", descending: true)

        if let artistName = artistName {
            query = query.whereField("artist", isEqualTo: artistName)
        }

        do {
            let snapshot = try await query.getDocuments()
            personalAlbums = snapshot.documents.compactMap { try? $0.data(as: Album.self) }
            isLoading = false
        } catch {
            localError = AppError(message: "Error loading personal albums: \(error.localizedDescription)")
            isLoading = false
        }
    }

    private func removeAlbum(_ album: Album) async {
        guard let albumId = album.id else { return }
        isLoading = true
        localError = nil

        await withCheckedContinuation { continuation in
            session.deleteAlbumFromLibrary(albumId: albumId) { error in
                if let error = error {
                    localError = AppError(message: "Failed to remove album: \(error.localizedDescription)")
                } else {
                    libraryAlbums.removeAll { $0.id == albumId }
                }
                isLoading = false
                continuation.resume()
            }
        }
    }

    private func removePersonalAlbum(_ album: Album) async {
        guard let albumId = album.id else { return }
        isLoading = true
        localError = nil

        await withCheckedContinuation { continuation in
            session.deletePersonalAlbum(albumId: albumId) { error in
                if let error = error {
                    localError = AppError(message: "Failed to remove personal album: \(error.localizedDescription)")
                } else {
                    personalAlbums.removeAll { $0.id == albumId }
                }
                isLoading = false
                continuation.resume()
            }
        }
    }
}
