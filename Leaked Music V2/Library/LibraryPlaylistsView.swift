import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct LibraryPlaylistsView: View {
    @EnvironmentObject var session: SessionStore
    @State private var playlists: [Playlist] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Full-screen gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                List {
                    if isLoading {
                        HStack { Spacer(); ProgressView("Loading playlists...").foregroundColor(.white); Spacer() }
                    } else if playlists.isEmpty {
                        Text("No playlists found.")
                            .foregroundColor(.white)
                    } else {
                        ForEach(playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                HStack {
                                    Text(playlist.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("My Playlists")
            .alert(item: $localError) { error in
                Alert(title: Text("Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK")))
            }
            .onAppear(perform: loadPlaylists)
        }
    }
    
    private func loadPlaylists() {
        guard let uid = session.currentUser?.uid else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users")
            .document(uid)
            .collection("playlists")
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: "Error loading playlists: \(error.localizedDescription)")
                } else if let docs = snapshot?.documents {
                    playlists = docs.compactMap { try? $0.data(as: Playlist.self) }
                }
                isLoading = false
            }
    }
}
