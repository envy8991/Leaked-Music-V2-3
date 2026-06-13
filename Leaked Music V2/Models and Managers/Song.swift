import Foundation
import SwiftUI
import FirebaseFirestore

// MARK: - Song Model

struct Song: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var title: String
    var title_lower: String?      // e.g., songTitle.lowercased()
    var artist: String
    var audioURL: String
    var downloadCount: Int
    var isFeatured: Bool
    var artworkURL: String?
    var uploadedAt: Timestamp?

    // For linking to an album
    var albumId: String?
    var albumTitle: String?
    var albumArtist: String?

    // New fields for personal uploads
    var uploadType: String?       // e.g., "personal" if this song was uploaded by the user
    var uploadedBy: String?       // the UID of the uploader
}

// MARK: - DownloadedSong Model

struct DownloadedSong: Codable, Identifiable {
    var id: String?
    var title: String
    var title_lower: String?      // New field for ordering
    var artist: String
    var audioURL: String
    var downloadCount: Int
    var isFeatured: Bool
    var artworkURL: String?
    var uploadedAt: Timestamp?
    var albumId: String?
    var albumTitle: String?
    var albumArtist: String?

    // New fields for personal uploads
    var uploadType: String?
    var uploadedBy: String?

    // Initialize from a Song.
    init(from song: Song) {
        self.id = song.id
        self.title = song.title
        self.title_lower = song.title_lower
        self.artist = song.artist
        self.audioURL = song.audioURL
        self.downloadCount = song.downloadCount
        self.isFeatured = song.isFeatured
        self.artworkURL = song.artworkURL
        self.uploadedAt = song.uploadedAt
        self.albumId = song.albumId
        self.albumTitle = song.albumTitle
        self.albumArtist = song.albumArtist
        self.uploadType = song.uploadType
        self.uploadedBy = song.uploadedBy
    }

    // Convert back to a Song.
    func toSong() -> Song {
        return Song(
            id: id,
            title: title,
            title_lower: title_lower,
            artist: artist,
            audioURL: audioURL,
            downloadCount: downloadCount,
            isFeatured: isFeatured,
            artworkURL: artworkURL,
            uploadedAt: uploadedAt,
            albumId: albumId,
            albumTitle: albumTitle,
            albumArtist: albumArtist,
            uploadType: uploadType,
            uploadedBy: uploadedBy
        )
    }
}

// MARK: - Album Model

struct Album: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var title_lower: String?   // e.g., albumTitle.lowercased()
    var artist: String
    var coverURL: String
    var uploadedAt: Timestamp?
    var audioURLs: [String]?

    // New fields for personal uploads
    var uploadType: String?    // e.g., "personal" if this album was uploaded by the user
    var uploadedBy: String?    // the UID of the uploader
}


struct Artist: Identifiable, Codable, Equatable, Hashable { // Hashable Conformance Added Here
    @DocumentID var id: String? // Firestore document ID, optional
    let name: String
    var imageURL: String? // Optional field for the artist's image URL
}
