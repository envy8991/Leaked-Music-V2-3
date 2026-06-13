import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PlaylistPickerView: View {
    @EnvironmentObject var session: SessionStore
    let song: Song
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var playlists: [Playlist] = []
    @State private var newPlaylistName: String = ""
    @State private var showCreateField = false
    @State private var isLoading = false
    @State private var errorMsg: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    if isLoading {
                        ProgressView("Loading Playlists...")
                            .foregroundColor(.white)
                    } else {
                        List {
                            Section(header: Text("Your Playlists").foregroundColor(.white).font(.headline)) {
                                if playlists.isEmpty {
                                    Text("No playlists found.").foregroundColor(.white.opacity(0.8))
                                } else {
                                    ForEach(playlists) { playlist in
                                        Button {
                                            addSong(to: playlist)
                                        } label: {
                                            Text(playlist.name).foregroundColor(.white)
                                        }
                                    }
                                }
                            }
                            
                            Section(header: Text("Create New Playlist").foregroundColor(.white).font(.headline)) {
                                if showCreateField {
                                    VStack(spacing: 8) {
                                        TextField("Playlist Name", text: $newPlaylistName)
                                            .padding()
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(10)
                                        HStack {
                                            Spacer()
                                            Button("Add Playlist") {
                                                createNewPlaylist()
                                            }
                                            .foregroundColor(.white)
                                        }
                                    }
                                } else {
                                    Button("Create Playlist") {
                                        withAnimation {
                                            showCreateField = true
                                        }
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle("Add to Playlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .onAppear { loadPlaylists() }
            .alert(item: Binding(
                get: { errorMsg.map { AppError(message: $0) } },
                set: { _ in errorMsg = nil }
            )) { err in
                Alert(title: Text("Error"), message: Text(err.message), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func loadPlaylists() {
        guard let uid = session.currentUser?.uid else {
            errorMsg = "User not logged in."
            return
        }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users")
            .document(uid)
            .collection("playlists")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    errorMsg = "Failed to load playlists: \(error.localizedDescription)"
                } else {
                    playlists = snapshot?.documents.compactMap { try? $0.data(as: Playlist.self) } ?? []
                }
            }
    }
    
    private func addSong(to playlist: Playlist) {
        session.addSongToPlaylist(song, playlist: playlist) { err in
            if let err = err {
                errorMsg = "Failed to add song: \(err.localizedDescription)"
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func createNewPlaylist() {
        guard !newPlaylistName.isEmpty else {
            errorMsg = "Please enter a playlist name"
            return
        }
        guard let songId = song.id else {
            errorMsg = "Invalid song ID"
            return
        }
        isLoading = true
        session.createPlaylist(name: newPlaylistName, coverImage: nil, songIDs: [songId]) { playlist, error in
            isLoading = false
            if let error = error {
                errorMsg = "Failed to create playlist: \(error.localizedDescription)"
            } else if playlist != nil {
                presentationMode.wrappedValue.dismiss()
            } else {
                errorMsg = "Failed to create playlist: Unknown error"
            }
        }
    }
}
