//
//  ManageArtistsViewModel.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/10/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class ManageArtistsViewModel: ObservableObject {
    @Published var artists: [Artist] = []
    
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    init() {
        fetchArtists()
    }
    
    func fetchArtists() {
        listener?.remove()
        listener = db.collection("artists")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error fetching artists: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    self?.artists = snapshot.documents.compactMap { try? $0.data(as: Artist.self) }
                }
            }
    }
    
    func uploadArtistImage(_ image: UIImage, for artist: Artist) {
        guard let artistId = artist.id else { return }
        let storageRef = Storage.storage().reference().child("artistImages/\(artistId).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
            } else {
                storageRef.downloadURL { url, error in
                    if let url = url {
                        self.db.collection("artists").document(artistId).updateData(["imageURL": url.absoluteString]) { error in
                            if let error = error {
                                print("Error updating artist: \(error.localizedDescription)")
                            }
                            // Snapshot listener will update the UI automatically
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}
