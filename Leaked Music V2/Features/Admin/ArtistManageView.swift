//
//  ArtistManageView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/13/25.
//


import SwiftUI
import FirebaseFirestore

struct ArtistManageView: View {
    var artist: Artist
    @State private var albums: [Album] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading albums...")
            } else {
                List {
                    ForEach(albums) { album in
                        NavigationLink(destination: AlbumManageView(album: album, artist: artist)) {
                            Text(album.title)
                        }
                    }
                }
            }
        }
        .navigationTitle(artist.name)
        .onAppear(perform: loadAlbums)
        .alert(item: $localError) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func loadAlbums() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("albums")
            .whereField("artist", isEqualTo: artist.name)
            .order(by: "title_lower")
            .getDocuments { snapshot, error in
                isLoading = false
                if let error = error {
                    localError = AppError(message: "Error loading albums: \(error.localizedDescription)")
                    return
                }
                albums = snapshot?.documents.compactMap { try? $0.data(as: Album.self) } ?? []
            }
    }
}