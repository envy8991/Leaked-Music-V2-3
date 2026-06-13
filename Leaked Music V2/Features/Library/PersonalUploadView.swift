import SwiftUI
import AVFoundation
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import UniformTypeIdentifiers
import Combine

struct PersonalUploadView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionStore

    // MARK: - File Selection & State
    @State private var selectedFileURLs: [URL] = []
    @State private var showFilePicker = false
    @State private var isUploading = false
    @State private var errorMessage: AppError? = nil
    @State private var toastMessage: String? = nil

    // MARK: - Song Upload Fields
    @State private var songTitle: String = ""
    @State private var songArtist: String = "Unknown Artist" // Default Artist for songs
    @State private var isFeatured: Bool = false // Feature toggle - might not be needed for personal uploads, but kept for consistency

    // MARK: - Cover/Album Art
    @State private var coverArtImage: Image? = nil
    @State private var selectedCoverUIImage: UIImage? = nil
    @State private var showCoverArtPicker = false

    // MARK: - Album Upload Fields
    @State private var albumTitle: String = ""
    @State private var albumArtist: String = "Unknown Artist" // Default artist for albums

    // Toggle Between Song and Album Upload
    @State private var isSong: Bool = true

    // MARK: - Progress Tracking
    @State private var overallProgress: Double = 0.0
    @State private var uploadedFilesCount: Int = 0

    // For album mode: store extracted metadata for each file
    @State private var albumTrackMetadata: [TrackMetadata] = []


    var body: some View {
        NavigationView {
            Form {
                // File Selection Section
                Section(header: Text("Select File\(isSong ? "" : "s")")) {
                    Button(action: { showFilePicker = true }) {
                        HStack {
                            Image(systemName: "doc.music.fill")
                            if isSong {
                                Text(selectedFileURLs.first == nil
                                     ? "Choose File"
                                     : selectedFileURLs.first!.lastPathComponent)
                            } else {
                                if selectedFileURLs.isEmpty {
                                    Text("Choose Files")
                                } else {
                                    Text("\(selectedFileURLs.count) files selected")
                                }
                            }
                        }
                    }
                }

                // Cover/Album Art Section
                Section(header: Text(isSong ? "Cover Art" : "Album Art")) {
                    HStack {
                        if let coverArtImage = coverArtImage {
                            coverArtImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipped()
                                .cornerRadius(8)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    Text("No Art")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                )
                        }
                        Button("Select \(isSong ? "Cover" : "Album") Art") {
                            showCoverArtPicker = true
                        }
                        .padding(.leading, 8)
                    }
                }

                // Metadata Section
                Section(header: Text("Metadata")) {
                    if isSong {
                        TextField("Song Title (Defaults to filename)", text: $songTitle)
                        TextField("Artist Name (Defaults to 'Unknown Artist')", text: $songArtist)
                       // Toggle("Featured", isOn: $isFeatured) // Feature toggle - might not be relevant for personal uploads
                        TextField("Album Title (Optional, for song context)", text: $albumTitle) // Album Title for single song context
                    } else {
                        TextField("Album Title", text: $albumTitle)
                        // **UPDATED LABEL - for clarity if needed**
                        TextField("Album Artist Name (Optional - Album Level Artist)", text: $albumArtist)
                    }
                }

                // Upload Progress Section
                if isUploading {
                    Section(header: Text("Upload Progress")) {
                        ProgressView(value: overallProgress)
                        if isSong {
                            Text("Uploading: \(Int(overallProgress * 100))%")
                                .font(.caption)
                        } else {
                            Text("Uploaded \(uploadedFilesCount) of \(selectedFileURLs.count) files")
                                .font(.caption)
                        }
                    }
                }

                // Upload Button Section
                Section {
                    Button(action: uploadPersonalContent) { // Unified upload function
                        HStack {
                            Spacer()
                            if isUploading {
                                ProgressView()
                            } else {
                                Text("Upload to Personal Library").bold()
                            }
                            Spacer()
                        }
                    }
                    .disabled(selectedFileURLs.isEmpty || isUploading)
                }
            }
            .navigationTitle("Personal Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) { // Toggle Button
                    Picker("Type", selection: $isSong) {
                        Text("Song").tag(true)
                        Text("Album").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                }
            }
            .sheet(isPresented: $showFilePicker) {
                FilePickerView(fileURLs: $selectedFileURLs,
                               allowsMultipleSelection: !isSong, // Allow multiple for albums
                               onPicked: { urls in
                                   selectedFileURLs = urls
                                   if isSong {
                                       if let firstURL = urls.first {
                                           fillFormUsingMetadata(fileURL: firstURL)
                                       }
                                   } else {
                                       albumTrackMetadata = urls.map { parseMetadataForFile($0) }
                                       autoFillAlbumFieldsAndArtwork()
                                   }
                               })
            }
            .sheet(isPresented: $showCoverArtPicker) {
                ImagePicker(image: $selectedCoverUIImage)
                    .onDisappear {
                        if let uiImage = selectedCoverUIImage {
                            coverArtImage = Image(uiImage: uiImage)
                        }
                    }
            }
            .alert(item: $errorMessage) { error in
                Alert(title: Text("Upload Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK")))
            }
            .toast(message: $toastMessage)
        }
    }


    // MARK: - Fill Form Using Metadata (Single File) - Reused from UploadContentView
    private func fillFormUsingMetadata(fileURL: URL) {
        let meta = parseMetadataForFile(fileURL)
        songTitle = meta.title
        songArtist = meta.artist
        albumTitle = meta.albumTitle.isEmpty ? meta.title : meta.albumTitle
        if let art = meta.artwork {
            coverArtImage = Image(uiImage: art)
            selectedCoverUIImage = art
        }
    }

    // MARK: - Auto-fill Album Fields & Artwork (Multi-file) - Reused from UploadContentView
    private func autoFillAlbumFieldsAndArtwork() {
        for track in albumTrackMetadata {
            if !track.albumTitle.isEmpty && albumTitle.isEmpty {
                albumTitle = track.albumTitle
            }
            if let art = track.artwork, coverArtImage == nil {
                coverArtImage = Image(uiImage: art)
                selectedCoverUIImage = art
            }
        }
        // In PersonalUploadView, album artist is *optional* and more for album-level info.
        // We don't want to autofill songArtist from album tracks as strongly as in UploadContentView for global albums.
        // Users might want different artists for tracks on personal albums.
        // if albumArtist.isEmpty, let firstArtist = albumTrackMetadata.first?.artist, !firstArtist.isEmpty {
        //     albumArtist = firstArtist //  Not auto-filling albumArtist as strictly for personal albums
        // }
        if albumTitle.isEmpty { albumTitle = "Untitled Album" }
    }

    // MARK: - Parse Metadata for a Single File - Reused from UploadContentView
    private func parseMetadataForFile(_ fileURL: URL) -> TrackMetadata {
        let asset = AVAsset(url: fileURL)
        var extractedTitle = ""
        var extractedArtist = ""
        var extractedAlbumTitle = ""
        var extractedArtwork: UIImage? = nil

        for item in asset.commonMetadata {
            if let key = item.commonKey?.rawValue {
                switch key {
                case "title":
                    if let val = item.stringValue { extractedTitle = val }
                case "artist":
                    if let val = item.stringValue { extractedArtist = val }
                case "albumName":
                    if let val = item.stringValue { extractedAlbumTitle = val }
                case "artwork":
                    if let data = item.dataValue, let ui = UIImage(data: data) {
                        extractedArtwork = ui
                    }
                default: break
                }
            }
        }
        if extractedTitle.isEmpty {
            extractedTitle = fileURL.deletingPathExtension().lastPathComponent
        }
        if extractedArtist.isEmpty {
            extractedArtist = "Unknown Artist"
        }

        return TrackMetadata(
            fileURL: fileURL,
            title: extractedTitle,
            artist: extractedArtist,
            albumTitle: extractedAlbumTitle,
            artwork: extractedArtwork
        )
    }


    // MARK: - Unified Upload Handling for Song and Album - Modified for Personal Library
    private func uploadPersonalContent() {
        guard !selectedFileURLs.isEmpty, let userId = session.currentUser?.uid else { return }
        isUploading = true
        overallProgress = 0.0

        let storageRef = Storage.storage().reference().child("personalUploads/\(userId)") // Personal uploads folder

        if isSong {
            uploadPersonalSongFile(storageRef: storageRef)
        } else {
            uploadPersonalAlbumFiles(storageRef: storageRef)
        }
    }


    // MARK: - Upload Personal Song File (Single Song Mode)
    private func uploadPersonalSongFile(storageRef: StorageReference) {
        guard let fileURL = selectedFileURLs.first, let userId = session.currentUser?.uid else { return }
        let fileName = "\(UUID().uuidString)_\(fileURL.lastPathComponent)"
        let fileRef = storageRef.child("songs/\(fileName)") // songs subfolder within personal uploads

        let uploadTask = fileRef.putFile(from: fileURL, metadata: nil) { metadata, error in
            if let error = error {
                self.errorMessage = AppError(message: "Personal song upload error: \(error.localizedDescription)")
                self.isUploading = false
                return
            }
            fileRef.downloadURL { url, error in
                guard let downloadURL = url else {
                    self.errorMessage = AppError(message: "Failed to retrieve personal song download URL.")
                    self.isUploading = false
                    return
                }
                let artworkURLString = self.coverArtUploadForPersonal(storageRef: storageRef)
                { artURL in
                    self.addPersonalSongToFirestore(downloadURL: downloadURL, artworkURL: artURL)
                }

                if artworkURLString == nil { // if no cover art upload, proceed without waiting
                    self.addPersonalSongToFirestore(downloadURL: downloadURL, artworkURL: nil)
                }
            }
        }

        uploadTask.observe(.progress) { snapshot in
            let completed = Double(snapshot.progress?.completedUnitCount ?? 0)
            let total = Double(snapshot.progress?.totalUnitCount ?? 1)
            self.overallProgress = completed / total
        }
    }


    // MARK: - Upload Personal Album Files (Album Mode)
    private func uploadPersonalAlbumFiles(storageRef: StorageReference) {
        guard let userId = session.currentUser?.uid else { return }
        uploadedFilesCount = 0
        var trackURLs = Array<String?>(repeating: nil, count: selectedFileURLs.count)
        var uploadError: Error? = nil
        let totalFiles = selectedFileURLs.count
        let group = DispatchGroup()

        for (index, fileURL) in selectedFileURLs.enumerated() {
            group.enter()
            let fileName = "\(UUID().uuidString)_\(fileURL.lastPathComponent)"
            let fileRef = storageRef.child("albumTracks/\(fileName)") // albumTracks subfolder

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
                    self.uploadedFilesCount += 1
                    self.overallProgress = Double(self.uploadedFilesCount) / Double(totalFiles)
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            if let error = uploadError {
                self.errorMessage = AppError(message: "Error uploading album files: \(error.localizedDescription)")
                self.isUploading = false
            } else {
                let finalTrackURLs = trackURLs.compactMap { $0 }
                let artworkURLString = self.coverArtUploadForPersonal(storageRef: storageRef)
                { artURL in
                    self.createPersonalAlbumAndSongs(coverURL: artURL, trackURLs: finalTrackURLs)
                }
                if artworkURLString == nil { // if no cover art upload, proceed without waiting
                    self.createPersonalAlbumAndSongs(coverURL: nil, trackURLs: finalTrackURLs)
                }
            }
        }
    }


    // MARK: - Cover Art Upload for Personal Content (DRY)
    private func coverArtUploadForPersonal(storageRef: StorageReference, completion: @escaping (String?) -> Void) -> String? {
        if let coverImg = self.selectedCoverUIImage {
            let coverRef = storageRef.child("coverArt/\(UUID().uuidString).jpg") // coverArt subfolder
            guard let data = coverImg.jpegData(compressionQuality: 0.8) else {
                completion(nil)
                return nil
            }
            coverRef.putData(data, metadata: nil) { _, err in
                if let err = err {
                    print("Personal cover art upload error: \(err.localizedDescription)")
                    completion(nil)
                    return
                }
                coverRef.downloadURL { url, err in
                    completion(url?.absoluteString)
                }
            }
            return "uploading" // Indicate that upload is in progress
        } else {
            completion(nil)
            return nil // No cover art to upload
        }
    }


    // MARK: - Add Personal Song to Firestore (Single Song Mode) - Modified for personal library
    private func addPersonalSongToFirestore(downloadURL: URL, artworkURL: String?) {
        guard let userId = session.currentUser?.uid else {
            isUploading = false
            return
        }
        let db = Firestore.firestore()
        let personalSongRef = db.collection("users").document(userId).collection("personalSongs").document()


        let finalSongTitle = songTitle.isEmpty ? selectedFileURLs.first!.deletingPathExtension().lastPathComponent : songTitle
        let finalArtistName = isSong ? songArtist : albumArtist // Use songArtist for song mode, albumArtist for album mode for consistency


        let songData: [String: Any] = [
            "id": personalSongRef.documentID,
            "title": finalSongTitle,
            "title_lower": finalSongTitle.lowercased(),
            "artist": finalArtistName,
            "artist_lower": finalArtistName.lowercased(),
            "audioURL": downloadURL.absoluteString,
            "uploadedAt": Timestamp(date: Date()),
            "downloadCount": 0,
            "isFeatured": isFeatured, // You might decide to remove "isFeatured" for personal uploads
            "artworkURL": artworkURL ?? "",
            "albumId": "personal", // Or generate a unique ID if you want to manage personal albums as separate entities
            "albumTitle": isSong ? (albumTitle.isEmpty ? "Personal Uploads" : albumTitle) : albumTitle, // Album title might be relevant even for single song upload in personal library
            "albumArtist": finalArtistName,
            "albumTitle_lower": isSong ? (albumTitle.isEmpty ? "personal uploads" : albumTitle.lowercased()) : albumTitle.lowercased(),
            "albumArtist_lower": finalArtistName.lowercased(),
            "uploadType": "personal",
            "uploadedBy": userId
        ]

        personalSongRef.setData(songData) { error in
            self.isUploading = false
            if let error = error {
                self.errorMessage = AppError(message: "Error adding personal song to library: \(error.localizedDescription)")
            } else {
                self.toastMessage = "Personal song uploaded successfully!"
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.toastMessage = nil
                }
                dismiss() // Dismiss after successful upload
            }
        }
    }


    // MARK: - Create Personal Album and Songs (Album Mode) - Modified for personal library
    private func createPersonalAlbumAndSongs(coverURL: String?, trackURLs: [String]) {
        guard let userId = session.currentUser?.uid else {
            isUploading = false
            return
        }
        let db = Firestore.firestore()
        let albumDocRef = db.collection("users").document(userId).collection("personalAlbums").document() // Personal albums collection
        let personalAlbumId = albumDocRef.documentID

        let albumData: [String: Any] = [
            "id": personalAlbumId,
            "title": albumTitle,
            "title_lower": albumTitle.lowercased(),
            "artist": albumArtist, // Album Artist for personal album document itself
            "artist_lower": albumArtist.lowercased(),
            "coverURL": coverURL ?? "",
            "uploadedAt": Timestamp(date: Date()),
            "audioURLs": trackURLs,
            "uploadType": "personal",
            "uploadedBy": userId
        ]
        albumDocRef.setData(albumData) { error in
            if let error = error {
                self.isUploading = false
                self.errorMessage = AppError(message: "Error adding personal album: \(error.localizedDescription)")
                return
            }
            self.createPersonalSongsForAlbum(personalAlbumId: personalAlbumId, albumArtistName: albumArtist, coverURL: coverURL, trackURLs: trackURLs)
        }
    }


    /// Creates personal Song documents for each track in the personal album.
    private func createPersonalSongsForAlbum(personalAlbumId: String, albumArtistName: String, coverURL: String?, trackURLs: [String]) {
        guard let userId = session.currentUser?.uid else { return }
        let db = Firestore.firestore()
        let group = DispatchGroup()

        for (index, trackURL) in trackURLs.enumerated() {
            group.enter()
            let meta = albumTrackMetadata[index]
            let personalSongRef = db.collection("users").document(userId).collection("personalSongs").document() // Personal songs collection

            // **UPDATED: Get artist from track metadata, fallback to albumArtist if missing in metadata**
            let trackArtist = meta.artist.isEmpty ? albumArtistName : meta.artist
            let finalTrackArtist = trackArtist.isEmpty ? "Unknown Artist" : trackArtist // Default if even albumArtist is missing


            let songData: [String: Any] = [
                "id": personalSongRef.documentID,
                "title": meta.title,
                "title_lower": meta.title.lowercased(),
                // **UPDATED: Using trackArtist from metadata (or fallback)**
                "artist": finalTrackArtist,
                "artist_lower": finalTrackArtist.lowercased(),
                "audioURL": trackURL,
                "uploadedAt": Timestamp(date: Date()),
                "downloadCount": 0,
                "isFeatured": false, // Feature toggle - might not be relevant for personal uploads
                "artworkURL": coverURL ?? "",
                "albumId": personalAlbumId, // Link to the personal album
                "albumTitle": albumTitle,
                "albumArtist": albumArtistName, // Keep albumArtist as the *album's* artist
                "albumTitle_lower": albumTitle.lowercased(),
                "albumArtist_lower": albumArtistName.lowercased(),
                "uploadType": "personal",
                "uploadedBy": userId
            ]
            personalSongRef.setData(songData) { err in
                if let err = err {
                    print("Error creating personal album track doc: \(err.localizedDescription)")
                }
                // No need to update artist doc in "artists" collection for personal uploads in this version
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.isUploading = false
            self.toastMessage = "Personal album uploaded successfully!"
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.toastMessage = nil
            }
            // Dismiss after successful album upload
        }
    }
}
