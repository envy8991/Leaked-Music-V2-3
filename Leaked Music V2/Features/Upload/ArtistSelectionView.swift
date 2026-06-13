//
//  ArtistSelectionView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/13/25.
//


import SwiftUI

struct ArtistSelectionView: View {
    @ObservedObject var viewModel: UploadViewModel

    var body: some View {
        List {
            ForEach(viewModel.artists, id: \.id) { artist in
                NavigationLink(value: artist) {
                    Text(artist.name)
                        .foregroundColor(.primary) // Force text to be non-grey
                }
            }
            Button("Create New Artist") {
                viewModel.showCreateArtistSheet = true
            }
        }
        .navigationDestination(for: Artist.self) { artist in
            AlbumSelectionView(viewModel: viewModel, selectedArtist: artist)
        }
        .sheet(isPresented: $viewModel.showCreateArtistSheet) {
            CreateArtistView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.fetchArtists()
        }
    }
}
