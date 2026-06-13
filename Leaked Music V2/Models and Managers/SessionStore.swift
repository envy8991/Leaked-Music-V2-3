import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class SessionStore: ObservableObject {
    // Make this optional & weak to avoid a strong reference cycle
    weak var themeManager: ThemeManager? = nil
    
    @Published var isLoggedIn = false
    @Published var currentUser: UserProfile?
    @Published var appError: AppError? = nil
    @Published var toastMessage: String? = nil
    @Published var networkMonitor = NetworkMonitor()
    
    // Keep track of which songs the user has in library
    @Published var librarySongIDs: Set<String> = []
    
    // Follow functionality
    @Published var following: Set<String> = []
    
    // Friend functionality
    @Published var friendIDs: Set<String> = []
    
    private var authHandle: AuthStateDidChangeListenerHandle?
    private var libraryListener: ListenerRegistration?
    private var friendListener: ListenerRegistration?
    
    init() {
        Logger.log("SessionStore initialized")
        print("[SessionStore] init()")
        listen()
    }
    
    // MARK: - Auth Listener
    func listen() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            if let user = user {
                Logger.log("User logged in: \(user.uid)")
                DispatchQueue.main.async {
                    self.isLoggedIn = true
                }
                self.fetchUserProfile(uid: user.uid)
                self.fetchFollowing()
                self.listenToFriends()
            } else {
                Logger.log("User logged out")
                DispatchQueue.main.async {
                    self.isLoggedIn = false
                    self.currentUser = nil
                    self.librarySongIDs = []
                    self.following = []
                    self.friendIDs = []
                    self.libraryListener?.remove()
                    self.friendListener?.remove()
                }
            }
        }
    }
    
    // MARK: - Fetch User Profile
    func fetchUserProfile(uid: String) {
        guard !uid.isEmpty else {
            Logger.log("fetchUserProfile: Provided UID is empty")
            DispatchQueue.main.async {
                self.appError = AppError(message: "User UID is empty")
            }
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.appError = AppError(message: "Fetching profile failed: \(error.localizedDescription)")
                }
                Logger.log("Profile fetch error", error: error)
                return
            }
            
            guard let data = snapshot?.data() else {
                DispatchQueue.main.async {
                    self.appError = AppError(message: "Profile data missing for user")
                }
                Logger.log("Profile data missing for uid: \(uid)")
                return
            }
            
            let profile = UserProfile(data: data)
            
            // Update our SwiftUI state
            DispatchQueue.main.async {
                self.currentUser = profile
                self.listenToLibrarySongs()
            }
            Logger.log("Fetched profile for \(profile.username)")
            
            // Update isOnline to true after fetching the profile
            self.updateOnlineStatus(isOnline: true)
            
            // **Apply the user’s Firestore-based theme** to the local ThemeManager
            self.themeManager?.setThemeFromFirestore(profile.customTheme)
        }
    }
    
    // MARK: - Push new theme to Firestore
    /// Call this whenever user picks a new theme (from `SettingsView` or anywhere).
    func updateFirestoreTheme(primaryHex: String, secondaryHex: String) {
        guard let uid = currentUser?.uid else {
            print("DEBUG: updateFirestoreTheme called, but currentUser is nil or has no uid.")
            return
        }
        
        print("DEBUG: Attempting to update Firestore theme -> primary=\(primaryHex), secondary=\(secondaryHex)")
        
        let db = Firestore.firestore()
        let themeData: [String: Any] = [
            "primaryColorHex": primaryHex,
            "secondaryColorHex": secondaryHex
        ]
        
        db.collection("users").document(uid).updateData(["customTheme": themeData]) { error in
            if let error = error {
                print("Error updating custom theme: \(error.localizedDescription)")
            } else {
                print("Successfully updated Firestore theme for user \(uid) with primary=\(primaryHex), secondary=\(secondaryHex)")
            }
        }
    }
    
    // MARK: - Sign In / Sign Up
    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.appError = AppError(message: "Sign in failed: \(error.localizedDescription)")
                }
                Logger.log("Sign in error", error: error)
                return
            }
            Logger.log("User signed in")
            // The online status will be updated in fetchUserProfile.
        }
    }
    
    func signUp(email: String, password: String, username: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.appError = AppError(message: "Sign up failed: \(error.localizedDescription)")
                }
                Logger.log("Sign up error", error: error)
                return
            }
            guard let uid = result?.user.uid, !uid.isEmpty else {
                DispatchQueue.main.async {
                    self?.appError = AppError(message: "UID not found after sign up")
                }
                Logger.log("UID missing after sign up")
                return
            }
            // Provide a default customTheme in the user doc
            let userData: [String: Any] = [
                "uid": uid,
                "username": username,
                "isAdmin": false,
                "isPaid": false,
                "isOnline": true,
                "customTheme": [
                    "primaryColorHex": "#007AFF",
                    "secondaryColorHex": "#FFFFFF"
                ]
            ]
            let db = Firestore.firestore()
            db.collection("users").document(uid).setData(userData) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.appError = AppError(message: "User creation failed: \(error.localizedDescription)")
                    }
                    Logger.log("User creation error", error: error)
                } else {
                    Logger.log("User document created successfully for uid: \(uid)")
                    self?.fetchUserProfile(uid: uid)
                }
            }
        }
    }
    
    func signOut() {
        guard let uid = currentUser?.uid else {
            do { try Auth.auth().signOut() } catch { Logger.log("Sign out error", error: error) }
            DispatchQueue.main.async { self.resetSession() }
            Logger.log("User signed out (UID missing)")
            return
        }
        let db = Firestore.firestore()
        // Update online status to false when signing out
        db.collection("users").document(uid).updateData(["isOnline": false]) { [weak self] error in
            if let error = error {
                Logger.log("Error updating online status on sign out", error: error)
            }
            do {
                try Auth.auth().signOut()
                DispatchQueue.main.async { self?.resetSession() }
                Logger.log("User signed out")
            } catch {
                DispatchQueue.main.async {
                    self?.appError = AppError(message: "Sign out failed: \(error.localizedDescription)")
                }
                Logger.log("Sign out error", error: error)
            }
        }
    }
    
    private func resetSession() {
        self.isLoggedIn = false
        self.currentUser = nil
        self.librarySongIDs = []
        self.following = []
        self.friendIDs = []
        self.libraryListener?.remove()
        self.friendListener?.remove()
    }
    
    // MARK: - Update Online Status
    func updateOnlineStatus(isOnline: Bool) {
        guard let uid = currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["isOnline": isOnline]) { error in
            if let error = error {
                Logger.log("Error updating online status: \(error.localizedDescription)", error: error)
            } else {
                Logger.log("Updated online status to \(isOnline) for user \(uid)")
            }
        }
    }
    
    // MARK: - Library Management
    func listenToLibrarySongs() {
        guard let uid = currentUser?.uid, !uid.isEmpty else { return }
        let db = Firestore.firestore()
        libraryListener?.remove()
        libraryListener = db.collection("users").document(uid).collection("librarySongs")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    Logger.log("LibrarySongs listener error", error: error)
                } else if let snapshot = snapshot {
                    let ids = snapshot.documents.map { $0.documentID }
                    DispatchQueue.main.async {
                        self.librarySongIDs = Set(ids)
                    }
                    Logger.log("Updated librarySongIDs: \(self.librarySongIDs)")
                }
            }
    }
    
    func addSongToLibrary(_ song: Song, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, let songId = song.id else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user or song ID"])
            completion(error)
            return
        }
        let db = Firestore.firestore()
        let songRef = db.collection("users").document(uid).collection("librarySongs").document(songId)
        
        songRef.getDocument { snapshot, error in
            if let error = error {
                completion(error)
            } else if let snapshot = snapshot, snapshot.exists {
                let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Song is already in your library."])
                completion(error)
            } else {
                let data: [String: Any] = [
                    "title": song.title,
                    "artist": song.artist,
                    "audioURL": song.audioURL,
                    "downloadCount": song.downloadCount,
                    "isFeatured": song.isFeatured,
                    "artworkURL": song.artworkURL ?? "",
                    "uploadedAt": song.uploadedAt ?? Timestamp(date: Date()),
                    "albumId": song.albumId ?? "",
                    "albumTitle": song.albumTitle ?? "",
                    "albumArtist": song.albumArtist ?? ""
                ]
                songRef.setData(data) { err in
                    if let err = err {
                        completion(err)
                    } else {
                        if let albumId = song.albumId, !albumId.isEmpty {
                            self.addAlbumToLibraryIfNeeded(song: song, completion: completion)
                        } else {
                            completion(nil)
                        }
                    }
                }
            }
        }
    }
    
    private func addAlbumToLibraryIfNeeded(song: Song, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, let albumId = song.albumId, !albumId.isEmpty else {
            completion(nil)
            return
        }
        let db = Firestore.firestore()
        let albumRef = db.collection("users").document(uid).collection("libraryAlbums").document(albumId)
        albumRef.getDocument { snap, error in
            if let error = error {
                completion(error)
                return
            }
            if snap?.exists == true {
                completion(nil)
            } else {
                let data: [String: Any] = [
                    "albumId": albumId,
                    "title": song.albumTitle ?? song.title,
                    "artist": song.albumArtist ?? song.artist,
                    "coverURL": song.artworkURL ?? "",
                    "uploadedAt": song.uploadedAt ?? Timestamp(date: Date()),
                    "dateAdded": Timestamp(date: Date())
                ]
                albumRef.setData(data, completion: completion)
            }
        }
    }
    
    // MARK: - Add Song to Playlist
    func addSongToPlaylist(_ song: Song, playlist: Playlist, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, let songId = song.id, let playlistId = playlist.id else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing user, song, or playlist ID"])
            completion(error)
            return
        }
        let db = Firestore.firestore()
        let playlistRef = db.collection("users").document(uid).collection("playlists").document(playlistId)
        playlistRef.updateData([
            "songIDs": FieldValue.arrayUnion([songId])
        ]) { error in
            completion(error)
        }
    }
    
    // MARK: - Add Album to Library
    func addAlbumToLibrary(album: Album, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, let albumId = album.id else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user or album"])
            completion(error)
            return
        }
        let db = Firestore.firestore()
        let albumRef = db.collection("users").document(uid).collection("libraryAlbums").document(albumId)
        albumRef.getDocument { snapshot, error in
            if let error = error {
                completion(error)
            } else if let snapshot = snapshot, snapshot.exists {
                completion(nil)
            } else {
                let data: [String: Any] = [
                    "albumId": albumId,
                    "title": album.title,
                    "title_lower": album.title.lowercased(),
                    "artist": album.artist,
                    "artist_lower": album.artist.lowercased(),
                    "coverURL": album.coverURL,
                    "uploadedAt": album.uploadedAt ?? Timestamp(date: Date()),
                    "dateAdded": Timestamp(date: Date())
                ]
                albumRef.setData(data, completion: completion)
            }
        }
    }
    
    // MARK: - Create Playlist
    func createPlaylist(name: String,
                        coverImage: UIImage?,
                        songIDs: [String],
                        completion: @escaping (Playlist?, Error?) -> Void) {
        guard let uid = currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No current user."])
            completion(nil, error)
            return
        }
        let db = Firestore.firestore()
        let newDoc = db.collection("users").document(uid).collection("playlists").document()
        
        if let img = coverImage {
            uploadPlaylistCover(img) { [weak self] coverURL in
                if let coverURL = coverURL {
                    self?.finalizePlaylistCreation(docRef: newDoc, name: name, songIDs: songIDs, coverURL: coverURL, completion: completion)
                } else {
                    self?.useFirstSongArtworkIfAvailable(songIDs, docRef: newDoc, name: name, completion: completion)
                }
            }
        } else {
            useFirstSongArtworkIfAvailable(songIDs, docRef: newDoc, name: name, completion: completion)
        }
    }
    
    private func finalizePlaylistCreation(docRef: DocumentReference,
                                          name: String,
                                          songIDs: [String],
                                          coverURL: String?,
                                          completion: @escaping (Playlist?, Error?) -> Void) {
        let newPlaylist = Playlist(
            id: docRef.documentID,
            name: name,
            songIDs: songIDs,
            createdBy: currentUser?.uid,
            createdAt: Timestamp(date: Date()),
            coverURL: coverURL
        )
        
        do {
            try docRef.setData(from: newPlaylist) { err in
                if let err = err {
                    completion(nil, err)
                } else {
                    completion(newPlaylist, nil)
                }
            }
        } catch {
            completion(nil, error)
        }
    }
    
    private func useFirstSongArtworkIfAvailable(_ songIDs: [String],
                                                docRef: DocumentReference,
                                                name: String,
                                                completion: @escaping (Playlist?, Error?) -> Void) {
        guard !songIDs.isEmpty else {
            finalizePlaylistCreation(docRef: docRef, name: name, songIDs: songIDs, coverURL: nil, completion: completion)
            return
        }
        
        let db = Firestore.firestore()
        let firstSongId = songIDs[0]
        db.collection("songs").document(firstSongId).getDocument { [weak self] snap, err in
            if let _ = err {
                self?.finalizePlaylistCreation(docRef: docRef, name: name, songIDs: songIDs, coverURL: nil, completion: completion)
                return
            }
            if let snap = snap,
               let song = try? snap.data(as: Song.self),
               let fallbackCover = song.artworkURL,
               !fallbackCover.isEmpty {
                self?.finalizePlaylistCreation(docRef: docRef, name: name, songIDs: songIDs, coverURL: fallbackCover, completion: completion)
            } else {
                self?.finalizePlaylistCreation(docRef: docRef, name: name, songIDs: songIDs, coverURL: nil, completion: completion)
            }
        }
    }
    
    private func uploadPlaylistCover(_ image: UIImage, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference()
        let coverRef = storageRef.child("playlistCovers/\(UUID().uuidString).jpg")
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        coverRef.putData(data, metadata: nil) { _, err in
            if let err = err {
                print("Cover art upload error: \(err.localizedDescription)")
                completion(nil)
                return
            }
            coverRef.downloadURL { url, err in
                completion(url?.absoluteString)
            }
        }
    }
    
    // MARK: - Delete Song (and Possibly Album) from Library
    func deleteSongFromLibrary(song: Song, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, let songId = song.id else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user or song"])
            completion(error)
            return
        }
        
        let db = Firestore.firestore()
        let songRef = db.collection("users").document(uid).collection("librarySongs").document(songId)
        songRef.delete { error in
            if let error = error {
                print("Error deleting song \(song.title): \(error.localizedDescription)")
                completion(error)
            } else {
                print("Deleted song \(song.title) successfully.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let albumId = song.albumId, !albumId.isEmpty {
                        db.collection("users").document(uid).collection("librarySongs")
                            .whereField("albumId", isEqualTo: albumId)
                            .getDocuments { snapshot, error in
                                if let error = error {
                                    print("Error querying songs for album \(albumId): \(error.localizedDescription)")
                                    completion(error)
                                } else if let snapshot = snapshot {
                                    print("Found \(snapshot.documents.count) songs for album \(albumId)")
                                    if snapshot.documents.isEmpty {
                                        let albumRef = db.collection("users").document(uid).collection("libraryAlbums").document(albumId)
                                        albumRef.delete { albumDeleteError in
                                            if let albumDeleteError = albumDeleteError {
                                                print("Error deleting album \(albumId): \(albumDeleteError.localizedDescription)")
                                                completion(albumDeleteError)
                                            } else {
                                                print("Album \(albumId) deleted successfully because no songs remain.")
                                                completion(nil)
                                            }
                                        }
                                    } else {
                                        completion(nil)
                                    }
                                } else {
                                    completion(nil)
                                }
                            }
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Album and Associated Songs from Library (Global Albums)
    func deleteAlbumFromLibrary(albumId: String, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, !uid.isEmpty else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"])
            completion(error)
            return
        }
        let db = Firestore.firestore()
        let albumRef = db.collection("users").document(uid).collection("libraryAlbums").document(albumId)
        albumRef.delete { error in
            if let error = error {
                completion(error)
                return
            }
            let songsRef = db.collection("users").document(uid).collection("librarySongs")
            songsRef.whereField("albumId", isEqualTo: albumId).getDocuments { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }
                let batch = db.batch()
                snapshot?.documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                batch.commit { batchError in
                    completion(batchError)
                }
            }
        }
    }
    
    // MARK: - Delete Personal Album and Associated Songs
    func deletePersonalAlbum(albumId: String, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, !uid.isEmpty else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID"])
            completion(error)
            return
        }
        let db = Firestore.firestore()
        let albumRef = db.collection("users").document(uid).collection("personalAlbums").document(albumId)
        
        albumRef.delete { error in
            if let error = error {
                completion(error)
                return
            }
            let songsRef = db.collection("users").document(uid).collection("personalSongs")
            songsRef.whereField("albumId", isEqualTo: albumId).getDocuments { snapshot, error in
                if let error = error {
                    completion(error)
                    return
                }
                let batch = db.batch()
                snapshot?.documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                batch.commit { batchError in
                    completion(batchError)
                }
            }
        }
    }
    
    // MARK: - Delete Personal Song from Personal Library
    func deletePersonalSong(songId: String, completion: @escaping (Error?) -> Void) {
        guard let uid = currentUser?.uid, !uid.isEmpty else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID or song ID"])
            completion(error)
            return
        }
        
        let db = Firestore.firestore()
        let songRef = db.collection("users").document(uid).collection("personalSongs").document(songId)
        songRef.delete { error in
            completion(error)
        }
    }
    
    // MARK: - Friend Request & Friend List Management
    func sendFriendRequest(to userId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUid = currentUser?.uid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No logged in user"])
            completion(error)
            return
        }
        let db = Firestore.firestore()
        let friendRequestData: [String: Any] = [
            "from": currentUid,
            "to": userId,
            "timestamp": Timestamp(date: Date()),
            "status": "pending"
        ]
        db.collection("friendRequests").addDocument(data: friendRequestData, completion: completion)
    }
    
    func acceptFriendRequest(requestId: String, from userId: String, completion: @escaping (Error?) -> Void) {
        guard let currentUid = currentUser?.uid else { return }
        let db = Firestore.firestore()
        let batch = db.batch()
        
        let currentUserFriendRef = db.collection("users").document(currentUid).collection("friends").document(userId)
        let otherUserFriendRef = db.collection("users").document(userId).collection("friends").document(currentUid)
        batch.setData(["since": Timestamp(date: Date())], forDocument: currentUserFriendRef)
        batch.setData(["since": Timestamp(date: Date())], forDocument: otherUserFriendRef)
        
        let friendRequestRef = db.collection("friendRequests").document(requestId)
        batch.updateData(["status": "accepted"], forDocument: friendRequestRef)
        
        batch.commit(completion: completion)
    }
    
    func listenToFriends() {
        guard let uid = currentUser?.uid else { return }
        let db = Firestore.firestore()
        friendListener?.remove()
        friendListener = db.collection("users").document(uid).collection("friends")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    Logger.log("Friend listener error", error: error)
                } else if let snapshot = snapshot {
                    let ids = snapshot.documents.map { $0.documentID }
                    DispatchQueue.main.async {
                        self.friendIDs = Set(ids)
                    }
                    Logger.log("Updated friendIDs: \(self.friendIDs)")
                }
            }
    }
    
    // MARK: - Follow/Unfollow
    func fetchFollowing() {
        guard let uid = currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).collection("following")
            .addSnapshotListener { snapshot, error in
                if let snapshot = snapshot {
                    let ids = snapshot.documents.map { $0.documentID }
                    DispatchQueue.main.async {
                        self.following = Set(ids)
                    }
                }
            }
    }
    
    func followUser(_ userId: String) {
        guard let uid = currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid)
            .collection("following").document(userId)
            .setData(["followedAt": Timestamp(date: Date())]) { error in
                if let error = error {
                    Logger.log("Follow error", error: error)
                }
            }
    }
    
    func unfollowUser(_ userId: String) {
        guard let uid = currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid)
            .collection("following").document(userId)
            .delete { error in
                if let error = error {
                    Logger.log("Unfollow error", error: error)
                }
            }
    }
    
    // MARK: - Update Last Played Song
    func updateLastPlayedSong(songTitle: String?) {
        guard let uid = currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users").document(uid).updateData(["lastPlayedSongTitle": songTitle as Any]) { error in
            if let error = error {
                Logger.log("Error updating lastPlayedSongTitle", error: error)
            } else {
                Logger.log("Updated lastPlayedSongTitle to: \(songTitle ?? "nil")")
            }
        }
    }
}

// MARK: - UserProfile Model

struct UserProfile: Codable, Identifiable {
    var id: String { uid }
    var uid: String
    var username: String
    var isAdmin: Bool
    var isPaid: Bool
    var isOnline: Bool
    var avatarURL: String? = nil
    var bannerURL: String? = nil
    var bio: String? = nil
    var lastPlayedSongTitle: String? = nil
    
    // Firestore-based theme
    var customTheme: CustomTheme

    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.username = data["username"] as? String ?? "Unknown"
        self.isAdmin = data["isAdmin"] as? Bool ?? false
        self.isPaid = data["isPaid"] as? Bool ?? false
        self.isOnline = data["isOnline"] as? Bool ?? false
        self.avatarURL = data["avatarURL"] as? String
        self.bannerURL = data["bannerURL"] as? String
        self.bio = data["bio"] as? String
        self.lastPlayedSongTitle = data["lastPlayedSongTitle"] as? String
        
        // Parse customTheme from doc
        if let themeData = data["customTheme"] as? [String: Any],
           let primaryHex = themeData["primaryColorHex"] as? String {
            let secondaryHex = themeData["secondaryColorHex"] as? String ?? "#FFFFFF"
            self.customTheme = CustomTheme(primaryColorHex: primaryHex, secondaryColorHex: secondaryHex)
        } else {
            // Fallback if none
            self.customTheme = CustomTheme(primaryColorHex: "#007AFF", secondaryColorHex: "#FFFFFF")
        }
    }
}
