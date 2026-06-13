
//  Playlist.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/15/25.
//


import SwiftUI
import FirebaseFirestore


struct Playlist: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var songIDs: [String]
    var createdBy: String?
    var createdAt: Timestamp?
    
    /// NEW field: optional cover image URL
    var coverURL: String?
    
    // Adjust the initializer to include coverURL
    init(id: String? = nil,
         name: String,
         songIDs: [String],
         createdBy: String? = nil,
         createdAt: Timestamp? = nil,
         coverURL: String? = nil) {
        self.id = id
        self.name = name
        self.songIDs = songIDs
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.coverURL = coverURL
    }
}

