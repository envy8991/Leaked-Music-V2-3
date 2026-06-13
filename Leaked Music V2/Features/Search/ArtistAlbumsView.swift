//
//  ArtistAlbumsView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/19/25.
//


import SwiftUI
import FirebaseFirestore

struct ArtistAlbumsView: View {
    let artist: Artist
    @State private var albums: [Album] = []
    @State private var isLoading = true
    @State private var localError: AppError? = nil

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading Albums...")
                    .padding()
            } else if albums.isEmpty {
                Text("No albums found for \(artist.name).")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List(albums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumRow(album: album)
                    }
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle(artist.name)
        .alert(item: $localError) {
            Alert(title: Text("Error"),
                  message: Text($0.message),
                  dismissButton: .default(Text("OK"), action: { localError = nil }))
        }
        .onAppear(perform: loadAlbums)
        .appBackground()
    }
    
    private func loadAlbums() {
        isLoading = true
        let db = Firestore.firestore()
        // Assumes your albums documents have an "artist_lower" field.
        db.collection("albums")
            .whereField("artist_lower", isEqualTo: artist.name.lowercased())
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: "Failed to load albums: \(error.localizedDescription)")
                } else if let docs = snapshot?.documents {
                    albums = docs.compactMap { try? $0.data(as: Album.self) }
                }
                isLoading = false
            }
    }
}