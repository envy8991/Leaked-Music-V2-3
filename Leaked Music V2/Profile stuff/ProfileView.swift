import SwiftUI
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    @EnvironmentObject var session: SessionStore
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var avatarImage: Image? = nil
    @State private var showImagePicker = false
    @State private var selectedUIImage: UIImage? = nil
    @State private var localError: AppError? = nil
    @State private var errorWrapper: ErrorWrapper?  // For alerts
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Profile Header
                    VStack {
                        if let avatarURL = session.currentUser?.avatarURL, avatarImage == nil {
                            AsyncImage(url: URL(string: avatarURL)) { phase in
                                if let image = phase.image {
                                    image.resizable()
                                } else if phase.error != nil {
                                    Circle().fill(Color.gray.opacity(0.3))
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                        } else if let avatarImage = avatarImage {
                            avatarImage
                                .resizable()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Circle().fill(Color.gray.opacity(0.3))
                                .frame(width: 120, height: 120)
                        }
                        Text(username)
                            .font(.title)
                            .fontWeight(.bold)
                        Button(action: { showImagePicker = true }) {
                            Text("Change Avatar")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                    
                    // Action Buttons: Friend Requests, Friends, and Messages
                    HStack(spacing: 20) {
                        NavigationLink(destination: FriendRequestsView().environmentObject(session)) {
                            Text("Friend Requests")
                                .fontWeight(.semibold)
                                .padding()
                                .background(Color.purple.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        NavigationLink(destination: FriendsListView().environmentObject(session)) {
                            Text("Friends")
                                .fontWeight(.semibold)
                                .padding()
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        NavigationLink(destination: ConversationListView().environmentObject(session)) {
                            Text("Messages")
                                .fontWeight(.semibold)
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    // Subscription Status
                    GroupBox(label: Text("Subscription").font(.headline)) {
                        if session.currentUser?.isPaid == true || session.currentUser?.isAdmin == true {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("Premium Member")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Unlock exclusive features with Premium:")
                                Text("• Upload to Personal Library")
                                Text("• More features coming soon!")
                                Text("• Comment paid with your username in the paid category in the discord once subscribed")
                                Link(destination: URL(string: "https://buy.stripe.com/aEU7uV4dqebm3RK5kk")!) {
                                    Text("Subscribe Now")
                                        .fontWeight(.bold)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // Community Section
                    GroupBox(label: Text("Community").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Link(destination: URL(string: "https://discord.gg/zVXrU4UAzP")!) {
                                Text("Join our Discord")
                                    .foregroundColor(.blue)
                            }
                            Link(destination: URL(string: "https://x.com/leakedmp4?s=21")!) {
                                Text("Find us on X")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Settings & Help
                    GroupBox(label: Text("Settings & Help").font(.headline)) {
                        NavigationLink(destination: HelpView()) {
                            Text("Help & FAQ")
                                .foregroundColor(.blue)
                        }
                        NavigationLink(destination: SettingsView()) {
                            Text("App Settings")
                                .foregroundColor(.blue)
                        }
                        if session.currentUser?.isAdmin == true {
                            NavigationLink(destination: AdminView()) {
                                Text("Admin Panel")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    // Log Out
                    Button(action: { session.signOut() }) {
                        Text("Log Out")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .onAppear {
                if let profile = session.currentUser {
                    username = profile.username
                    bio = profile.bio ?? ""
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedUIImage)
                    .onDisappear {
                        if let uiImage = selectedUIImage {
                            avatarImage = Image(uiImage: uiImage)
                            uploadAvatar(uiImage)
                        }
                    }
            }
            .alert(item: $errorWrapper) { wrapper in
                Alert(title: Text("Error"),
                      message: Text(wrapper.message),
                      dismissButton: .default(Text("OK")))
            }
        }
        .appBackground()
    }
    
    private func uploadAvatar(_ image: UIImage) {
        guard let uid = session.currentUser?.uid else { return }
        let storageRef = Storage.storage().reference().child("avatars/\(uid)/avatar.jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                session.appError = AppError(message: "Avatar upload failed: \(error.localizedDescription)")
                Logger.log("Avatar upload error", error: error)
                return
            }
            storageRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    session.appError = AppError(message: "Failed to get avatar URL.")
                    return
                }
                let db = Firestore.firestore()
                db.collection("users").document(uid).updateData(["avatarURL": downloadURL.absoluteString]) { error in
                    if let error = error {
                        session.appError = AppError(message: "Failed to update avatar: \(error.localizedDescription)")
                        Logger.log("Avatar update error", error: error)
                    } else {
                        session.toastMessage = "Avatar updated"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { session.toastMessage = nil }
                        Logger.log("Avatar updated successfully")
                    }
                }
            }
        }
    }
}
