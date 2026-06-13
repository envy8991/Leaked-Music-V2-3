import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LibraryArtistsView: View {
    @EnvironmentObject var session: SessionStore // Import SessionStore to access currentUser
    @State private var artists: [String] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            List {
                if isLoading {
                    HStack { Spacer(); ProgressView("Loading...").foregroundColor(.white); Spacer() }
                } else if artists.isEmpty {
                    Text("No artists found in your library.")
                        .foregroundColor(.white.opacity(0.8))
                } else {
                    ForEach(artists, id: \.self) { artistName in
                        NavigationLink(destination: LibraryAlbumsView(artistName: artistName)) { // Changed to LibraryAlbumsView and pass artistName
                            Text(artistName)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Artists")
        .alert(item: $localError) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK")))
        }
        .onAppear(perform: loadLibraryArtists)
    }

    private func loadLibraryArtists() {
        guard let uid = Auth.auth().currentUser?.uid else {
            localError = AppError(message: "No user logged in")
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup() // Use DispatchGroup for concurrent fetches
        var globalArtists = Set<String>()
        var personalArtists = Set<String>()


        // 1. Fetch artists from GLOBAL library albums
        dispatchGroup.enter()
        db.collection("users")
            .document(uid)
            .collection("libraryAlbums")
            .getDocuments { snapshot, err in
                defer { dispatchGroup.leave() } // Ensure leave is called when exiting scope

                if let err = err {
                    print("Error loading global library artists: \(err.localizedDescription)") // Log error, but don't set localError yet
                    return
                }
                snapshot?.documents.forEach { doc in
                    if let artist = doc.data()["artist"] as? String, !artist.isEmpty {
                        globalArtists.insert(artist)
                    }
                }
            }

        // 2. Fetch artists from PERSONAL albums
        dispatchGroup.enter()
        db.collection("users")
            .document(uid)
            .collection("personalAlbums")
            .getDocuments { snapshot, err in
                defer { dispatchGroup.leave() } // Ensure leave is called when exiting scope
                if let err = err {
                    print("Error loading personal album artists: \(err.localizedDescription)") // Log error, but don't set localError yet
                    return
                }
                snapshot?.documents.forEach { doc in
                    if let artist = doc.data()["artist"] as? String, !artist.isEmpty {
                        personalArtists.insert(artist)
                    }
                }
            }


        dispatchGroup.notify(queue: .main) {
            artists = Array(globalArtists.union(personalArtists)).sorted() // Combine and sort artists from both sources
            isLoading = false
             if artists.isEmpty && globalArtists.isEmpty && personalArtists.isEmpty {
                localError = AppError(message: "No artists found in your library.") // Set error only if truly no artists found
            } else if let existingError = localError {
                // Keep existing error if it was set earlier during global or personal album fetching.
                print("Existing error was kept: \(existingError.message)")
            }
        }
    }
}
