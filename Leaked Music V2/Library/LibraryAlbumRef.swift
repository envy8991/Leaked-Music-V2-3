//
//  LibraryAlbumRef.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/15/25.
//


import SwiftUI
import FirebaseFirestore

struct LibraryAlbumRef: Identifiable, Codable {
    @DocumentID var id: String?         // doc ID in /users/{uid}/libraryAlbums
    var albumId: String                 // the ID of the album doc in the global "albums"
    var dateAdded: Timestamp
}
