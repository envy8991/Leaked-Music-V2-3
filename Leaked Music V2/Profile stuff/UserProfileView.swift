import SwiftUI
import FirebaseFirestore

struct UserProfileView: View {
    var user: UserProfile  // initial user snapshot from search results
    @EnvironmentObject var session: SessionStore
    @State private var playlists: [Playlist] = []
    @State private var localError: AppError? = nil
    @State private var isLoading = false

    // A state variable to hold the updated user data.
    @State private var updatedUser: UserProfile?
    // A Firestore listener for real-time updates.
    @State private var listener: ListenerRegistration?
    
    // State variable to track if a friend request is pending from current user to this profile.
    @State private var isRequestSent = false
    
    // Computed property: if updatedUser is available, use it; otherwise, fall back to the passed-in user.
    var displayUser: UserProfile {
        updatedUser ?? user
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Avatar and User Info Section
                HStack(spacing: 20) {
                    // Avatar Image
                    ZStack {
                        if let avatarURL = displayUser.avatarURL, let url = URL(string: avatarURL) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                case .failure:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                        .opacity(0.3)
                                @unknown default:
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                        .opacity(0.3)
                                }
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                                .opacity(0.3)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(displayUser.customTheme.primaryColor, lineWidth: 2))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text(displayUser.username)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        // User Status Display
                        HStack {
                            if displayUser.isAdmin {
                                CapsuleText(text: "Admin", color: .red)
                            } else if displayUser.isPaid {
                                CapsuleText(text: "Paid User", color: .green)
                            } else {
                                CapsuleText(text: "User", color: .blue)
                            }
                            CapsuleText(
                                text: displayUser.isOnline ? "Online" : "Offline",
                                color: displayUser.isOnline ? .green : .gray
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.vertical, 10)
                
                // Action Buttons Section
                HStack(spacing: 20) {
                    // Show "Add Friend" only if this profile is not the current user.
                    if displayUser.uid != session.currentUser?.uid {
                        if isRequestSent {
                            Text("Request Sent")
                                .foregroundColor(.gray)
                                .fontWeight(.semibold)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                        } else {
                            Button(action: {
                                session.sendFriendRequest(to: displayUser.uid) { error in
                                    if let error = error {
                                        localError = AppError(message: error.localizedDescription)
                                    } else {
                                        session.toastMessage = "Friend request sent!"
                                        isRequestSent = true
                                    }
                                }
                            }) {
                                Text("Add Friend")
                                    .fontWeight(.semibold)
                                    .padding()
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    
                    // Show "Message" if:
                    // - the profile is the current user, OR
                    // - the current user is already friends with the profile, OR
                    // - the profile is an admin (to allow messaging support)
                    if displayUser.uid == session.currentUser?.uid ||
                        session.friendIDs.contains(displayUser.uid) ||
                        displayUser.isAdmin {
                        NavigationLink(destination: ChatViewWrapper(targetUser: displayUser).environmentObject(session)) {
                            Text("Message")
                                .fontWeight(.semibold)
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    checkIfRequestSent()
                }
                
                // Playlists Section
                VStack(alignment: .leading) {
                    Text("Playlists")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 5)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if playlists.isEmpty {
                        Text("No playlists created yet.")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    } else {
                        ForEach(playlists, id: \.id) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                HStack {
                                    Image(systemName: "music.note.list")
                                        .foregroundColor(.secondary)
                                    Text(playlist.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical, 20)
        }
        .navigationTitle(displayUser.username)
        .onAppear {
            attachListener()
            loadPlaylists()
        }
        .onDisappear {
            listener?.remove()
        }
        .appBackground()
        .alert(item: $localError) {
            Alert(title: Text("Error"),
                  message: Text($0.message),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    /// Attach a Firestore listener to the user's document to update the profile in real time.
    private func attachListener() {
        let db = Firestore.firestore()
        listener = db.collection("users").document(user.uid)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    localError = AppError(message: "Failed to update profile: \(error.localizedDescription)")
                    return
                }
                if let data = snapshot?.data() {
                    updatedUser = UserProfile(data: data)
                }
            }
    }
    
    private func loadPlaylists() {
        guard !displayUser.uid.isEmpty else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users").document(displayUser.uid).collection("playlists")
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: "Error loading playlists: \(error.localizedDescription)")
                } else if let docs = snapshot?.documents {
                    playlists = docs.compactMap { document in
                        var playlist = try? document.data(as: Playlist.self)
                        playlist?.id = document.documentID
                        return playlist
                    }
                }
                isLoading = false
            }
    }
    
    // Check if a friend request is pending from the current user to the displayed user.
    private func checkIfRequestSent() {
        guard let currentUid = session.currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("friendRequests")
            .whereField("from", isEqualTo: currentUid)
            .whereField("to", isEqualTo: displayUser.uid)
            .whereField("status", isEqualTo: "pending")
            .getDocuments { snapshot, error in
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    isRequestSent = true
                } else {
                    isRequestSent = false
                }
            }
    }
}
