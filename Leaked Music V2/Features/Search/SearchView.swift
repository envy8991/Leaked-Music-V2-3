import SwiftUI
import FirebaseFirestore

struct SearchView: View {
    @State private var searchText = ""
    @State private var searchSongs: [Song] = []
    @State private var searchAlbums: [Album] = []
    @State private var searchArtists: [Artist] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil
    @State private var toastMessage: String? = nil
    @State private var debounceWorkItem: DispatchWorkItem?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Search Field
                    TextField("Search songs, albums, or artists", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .onChange(of: searchText) { newValue in
                            debounceWorkItem?.cancel()
                            let workItem = DispatchWorkItem {
                                performSearch(with: newValue)
                            }
                            debounceWorkItem = workItem
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
                        }
                    
                    if isLoading {
                        ProgressView("Searching...")
                            .padding()
                            .foregroundColor(.white)
                    } else {
                        // Results List with Artists at the top
                        List {
                            // Artists Section
                            if !searchArtists.isEmpty {
                                Section(header: Text("Artists")
                                            .foregroundColor(.white)
                                            .font(.headline)) {
                                    ForEach(searchArtists) { artist in
                                        NavigationLink(destination: ArtistAlbumsView(artist: artist)) {
                                            HStack {
                                                if let imageURL = artist.imageURL, let url = URL(string: imageURL) {
                                                    CachedAsyncImage(url: url)
                                                        .frame(width: 40, height: 40)
                                                        .clipShape(Circle())
                                                } else {
                                                    Circle()
                                                        .fill(Color.gray.opacity(0.5))
                                                        .frame(width: 40, height: 40)
                                                        .overlay(
                                                            Text(artist.name.prefix(1).uppercased())
                                                                .font(.headline)
                                                                .foregroundColor(.white)
                                                        )
                                                }
                                                Text(artist.name)
                                                    .font(.headline)
                                                    .foregroundColor(.white)
                                            }
                                            .padding(.vertical, 8)
                                        }
                                    }
                                }
                            }
                            
                            // Songs Section
                            if !searchSongs.isEmpty {
                                Section(header: Text("Songs")
                                            .foregroundColor(.white)
                                            .font(.headline)) {
                                    ForEach(searchSongs) { song in
                                        SongRow(originalSong: song, showAddButton: true)
                                    }
                                }
                            }
                            
                            // Albums Section
                            if !searchAlbums.isEmpty {
                                Section(header: Text("Albums")
                                            .foregroundColor(.white)
                                            .font(.headline)) {
                                    ForEach(searchAlbums) { album in
                                        NavigationLink(destination: AlbumDetailView(album: album)) {
                                            AlbumRow(album: album)
                                        }
                                    }
                                }
                            }
                            
                            // No Results Found
                            if searchSongs.isEmpty && searchAlbums.isEmpty && searchArtists.isEmpty && !searchText.isEmpty {
                                Text("No results found")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .listStyle(GroupedListStyle())
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle("Search")
            // Profile button in the top-right toolbar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.8))
                        .cornerRadius(10)
                    }
                }
            }
            .alert(item: $localError) { error in
                Alert(title: Text("Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK"), action: { localError = nil }))
            }
            .toast(message: $toastMessage)
        }
        .appBackground()
    }
    
    func performSearch(with query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchSongs = []
            searchAlbums = []
            searchArtists = []
            return
        }
        
        isLoading = true
        let lowerQuery = trimmed.lowercased()
        let db = Firestore.firestore()
        let group = DispatchGroup()
        
        // Search Songs
        group.enter()
        db.collection("songs")
            .order(by: "title_lower")
            .start(at: [lowerQuery])
            .end(at: [lowerQuery + "\u{f8ff}"])
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: "Song search failed: \(error.localizedDescription)")
                } else if let docs = snapshot?.documents {
                    searchSongs = docs.compactMap { try? $0.data(as: Song.self) }
                }
                group.leave()
            }
        
        // Search Albums
        group.enter()
        db.collection("albums")
            .order(by: "title_lower")
            .start(at: [lowerQuery])
            .end(at: [lowerQuery + "\u{f8ff}"])
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: "Album search failed: \(error.localizedDescription)")
                } else if let docs = snapshot?.documents {
                    searchAlbums = docs.compactMap { try? $0.data(as: Album.self) }
                }
                group.leave()
            }
        
        // Search Artists (from the songs collection, deduplicated)
        group.enter()
        db.collection("songs")
            .order(by: "artist_lower")
            .start(at: [lowerQuery])
            .end(at: [lowerQuery + "\u{f8ff}"])
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: "Artist search failed: \(error.localizedDescription)")
                } else if let docs = snapshot?.documents {
                    var artistNames: [String: String] = [:]
                    for doc in docs {
                        if let song = try? doc.data(as: Song.self) {
                            let artistName = song.artist  // Direct access, no optional binding
                            let lowerName = artistName.lowercased().trimmingCharacters(in: .whitespaces)
                            if artistNames[lowerName] == nil {
                                artistNames[lowerName] = artistName
                            }
                        }
                    }
                    // Map to Artist objects without IDs or imageURLs
                    searchArtists = artistNames.values.map { Artist(id: nil, name: $0, imageURL: nil) }
                    
                    // Fetch artist images from the artists collection
                    let artistNamesArray = Array(artistNames.values)
                    if !artistNamesArray.isEmpty {
                        db.collection("artists")
                            .whereField("name", in: artistNamesArray)
                            .getDocuments { artistSnapshot, artistError in
                                if let artistDocs = artistSnapshot?.documents {
                                    let fetchedArtists = artistDocs.compactMap { try? $0.data(as: Artist.self) }
                                    searchArtists = fetchedArtists
                                }
                            }
                    }
                }
                group.leave()
            }
        
        group.notify(queue: .main) {
            isLoading = false
            toastMessage = "Found \(searchSongs.count) songs, \(searchAlbums.count) albums, \(searchArtists.count) artists"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { toastMessage = nil }
        }
    }
}
