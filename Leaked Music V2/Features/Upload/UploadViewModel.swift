import SwiftUI
import AVFoundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import UniformTypeIdentifiers

class UploadViewModel: ObservableObject {
    @Published var artists: [Artist] = []
    @Published var albumsForSelectedArtist: [Album] = []
    @Published var selectedArtist: Artist? = nil
    @Published var selectedAlbum: Album? = nil
    @Published var showCreateArtistSheet = false
    @Published var showCreateAlbumSheet = false
    @Published var isUploading = false
    @Published var overallProgress: Double = 0.0
    @Published var errorMessage: AppError? = nil
    @Published var toastMessage: String? = nil

    private var db = Firestore.firestore()
    private var storageRef = Storage.storage().reference()
    private var albumsListener: ListenerRegistration? = nil

    init() {
        fetchArtists()
    }

    // MARK: - Fetch Artists
    func fetchArtists() {
        self.db.collection("artists")
            .order(by: "name_lower")
            .getDocuments { snapshot, error in
                print("fetchArtists() - Firestore query completed")
                if let error = error {
                    print("fetchArtists() - Error fetching artists: \(error.localizedDescription)")
                    self.errorMessage = AppError(message: "Error fetching artists: \(error.localizedDescription)")
                    return
                }
                print("fetchArtists() - Snapshot document count: \(snapshot?.documents.count ?? 0)")
                self.artists = snapshot?.documents.compactMap { document in
                    let artist = try? document.data(as: Artist.self)
                    print("fetchArtists() - Processed Artist: \(artist?.name ?? "nil")")
                    return artist
                } ?? []
                print("fetchArtists() - Final artists array count: \(self.artists.count)")
            }
    }

    // MARK: - Listen to Albums for Artist
    func listenToAlbumsForArtist(_ artist: Artist) {
        // Remove previous listener (if any) to avoid duplicate listeners
        albumsListener?.remove()
        albumsListener = db.collection("albums")
            .whereField("artist", isEqualTo: artist.name)
            .order(by: "title_lower")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    self.errorMessage = AppError(message: "Error fetching albums: \(error.localizedDescription)")
                    return
                }
                self.albumsForSelectedArtist = snapshot?.documents.compactMap { document in
                    try? document.data(as: Album.self)
                } ?? []
                print("listenToAlbumsForArtist() - Fetched \(self.albumsForSelectedArtist.count) albums for artist \(artist.name)")
            }
    }

    // MARK: - Create New Artist
    func createNewArtist(artistName: String, artistImage: UIImage?, completion: @escaping (Bool) -> Void) {
        isUploading = true
        uploadArtistImage(artistImage) { imageURL in
            let docID = artistName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let newArtistRef = self.db.collection("artists").document(docID)
            let artistData: [String: Any] = [
                "name": artistName,
                "name_lower": artistName.lowercased(),
                "imageURL": imageURL as Any
            ]
            newArtistRef.setData(artistData) { error in
                self.isUploading = false
                if let error = error {
                    self.errorMessage = AppError(message: "Error creating artist: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self.toastMessage = "Artist created successfully!"
                    self.fetchArtists() // Refresh artist list
                    completion(true)
                }
            }
        }
    }

    // MARK: - Create New Album
    func createNewAlbum(albumTitle: String, albumCover: UIImage?, artist: Artist, completion: @escaping (Bool) -> Void) {
        isUploading = true
        uploadAlbumCoverArt(albumCover) { coverURL in
            let newAlbumRef = self.db.collection("albums").document()
            let albumData: [String: Any] = [
                "title": albumTitle,
                "title_lower": albumTitle.lowercased(),
                "artist": artist.name,
                "artist_lower": artist.name.lowercased(),
                "coverURL": coverURL as Any,
                "uploadedAt": Timestamp(date: Date()),
                "audioURLs": [] // Initially empty
            ]
            newAlbumRef.setData(albumData) { error in
                self.isUploading = false
                if let error = error {
                    self.errorMessage = AppError(message: "Error creating album: \(error.localizedDescription)")
                    completion(false)
                } else {
                    self.toastMessage = "Album created successfully!"
                    // No need to call fetchAlbumsForArtist here because the snapshot listener is active.
                    completion(true)
                }
            }
        }
    }

    // MARK: - Upload Songs to Album
    func uploadSongsToAlbum(selectedArtist: Artist, selectedAlbum: Album, fileURLs: [URL], songTitles: [String], isFeatured: Bool, completion: @escaping (Bool) -> Void) {
        guard !fileURLs.isEmpty else { return }
        isUploading = true
        overallProgress = 0.0
        var uploadedFilesCount = 0
        var trackURLs = Array<String?>(repeating: nil, count: fileURLs.count)
        var uploadError: Error? = nil
        let totalFiles = fileURLs.count
        let group = DispatchGroup()
        
        for (index, fileURL) in fileURLs.enumerated() {
            group.enter()
            let fileName = "\(UUID().uuidString)_\(fileURL.lastPathComponent)"
            let fileRef = self.storageRef.child("uploads/\(fileName)")
            
            fileRef.putFile(from: fileURL, metadata: nil) { metadata, error in
                if let error = error {
                    uploadError = error
                    group.leave()
                    return
                }
                fileRef.downloadURL { url, error in
                    if let url = url {
                        trackURLs[index] = url.absoluteString
                    } else if let error = error {
                        uploadError = error
                    }
                    uploadedFilesCount += 1
                    self.overallProgress = Double(uploadedFilesCount) / Double(totalFiles)
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = uploadError {
                self.errorMessage = AppError(message: "Error uploading album files: \(error.localizedDescription)")
                self.isUploading = false
                completion(false)
            } else {
                let finalTrackURLs = trackURLs.compactMap { $0 }
                self.createSongsForAlbum(albumId: selectedAlbum.id!, albumTitle: selectedAlbum.title, artist: selectedArtist, trackURLs: finalTrackURLs, songTitles: songTitles, isFeatured: isFeatured) { success in
                    self.isUploading = false
                    completion(success)
                }
            }
        }
    }

    private func createSongsForAlbum(albumId: String, albumTitle: String, artist: Artist, trackURLs: [String], songTitles: [String], isFeatured: Bool, completion: @escaping (Bool) -> Void) {
        let group = DispatchGroup()
        for (index, trackURL) in trackURLs.enumerated() {
            group.enter()
            let songRef = self.db.collection("songs").document()
            let songTitle = songTitles.indices.contains(index) ? songTitles[index] : "Track \(index + 1)"
            let songData: [String: Any] = [
                "title": songTitle,
                "title_lower": songTitle.lowercased(),
                "artist": artist.name,
                "artist_lower": artist.name.lowercased(),
                "audioURL": trackURL,
                "uploadedAt": Timestamp(date: Date()),
                "downloadCount": 0,
                "isFeatured": isFeatured,
                "artworkURL": self.selectedAlbum?.coverURL ?? "",
                "albumId": albumId,
                "albumTitle": albumTitle,
                "albumArtist": artist.name,
                "albumTitle_lower": albumTitle.lowercased(),
                "albumArtist_lower": artist.name.lowercased()
            ]
            songRef.setData(songData) { err in
                if let err = err {
                    print("Error creating album track doc: \(err.localizedDescription)")
                } else {
                    self.updateArtistDocument(artistName: artist.name, songID: songRef.documentID, albumID: albumId)
                    self.updateAlbumDocument(albumID: albumId, songURL: trackURL)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.toastMessage = "Songs added to album successfully!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.toastMessage = nil
            }
            completion(true)
        }
    }

    // MARK: - Upload Images (Artist & Album Cover)
    private func uploadArtistImage(_ image: UIImage?, completion: @escaping (String?) -> Void) {
        guard let image = image, let data = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        let imageRef = self.storageRef.child("artistImages/\(UUID().uuidString).jpg")
        imageRef.putData(data, metadata: nil) { _, err in
            if let err = err {
                print("Artist image upload error: \(err.localizedDescription)")
                completion(nil)
                return
            }
            imageRef.downloadURL { url, err in
                completion(url?.absoluteString)
            }
        }
    }

    // Updated: Upload album cover art to the "coverArt" folder (same as the old UploadContentView)
    private func uploadAlbumCoverArt(_ image: UIImage?, completion: @escaping (String?) -> Void) {
        guard let image = image, let data = image.jpegData(compressionQuality: 0.8) else {
            completion(nil)
            return
        }
        let coverRef = self.storageRef.child("coverArt/\(UUID().uuidString).jpg")
        coverRef.putData(data, metadata: nil) { _, err in
            if let err = err {
                print("Album cover upload error: \(err.localizedDescription)")
                completion(nil)
                return
            }
            coverRef.downloadURL { url, err in
                completion(url?.absoluteString)
            }
        }
    }

    // MARK: - Update Artist and Album Documents
    private func updateArtistDocument(artistName: String, songID: String?, albumID: String?) {
        let docID = artistName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let artistRef = self.db.collection("artists").document(docID)
        
        artistRef.getDocument { snapshot, error in
            if let error = error {
                print("Error fetching artist document: \(error.localizedDescription)")
                return
            }
            if let snapshot = snapshot, snapshot.exists {
                var updates: [String: Any] = [
                    "name": artistName,
                    "name_lower": artistName.lowercased()
                ]
                if let songID = songID {
                    updates["songIDs"] = FieldValue.arrayUnion([songID])
                }
                if let albumID = albumID {
                    updates["albumIDs"] = FieldValue.arrayUnion([albumID])
                }
                artistRef.updateData(updates) { err in
                    if let err = err {
                        print("Error updating artist document: \(err.localizedDescription)")
                    }
                }
            } else {
                var data: [String: Any] = [
                    "name": artistName,
                    "name_lower": artistName.lowercased()
                ]
                if let songID = songID {
                    data["songIDs"] = [songID]
                }
                if let albumID = albumID {
                    data["albumIDs"] = [albumID]
                }
                artistRef.setData(data) { err in
                    if let err = err {
                        print("Error creating artist document: \(err.localizedDescription)")
                    }
                }
            }
        }
    }

    private func updateAlbumDocument(albumID: String, songURL: String) {
        let albumRef = self.db.collection("albums").document(albumID)
        albumRef.updateData([
            "audioURLs": FieldValue.arrayUnion([songURL])
        ]) { error in
            if let error = error {
                print("Error updating album document with song URL: \(error.localizedDescription)")
            }
        }
    }
}
