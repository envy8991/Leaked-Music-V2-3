//
//  ManageArtistsView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/10/25.
//


import SwiftUI

struct ManageArtistsView: View {
    @StateObject private var viewModel = ManageArtistsViewModel()
    @State private var selectedArtist: Artist?
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? // New state variable
    
    var body: some View {
        List(viewModel.artists) { artist in
            HStack {
                if let imageURL = artist.imageURL, let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } else {
                    Text(artist.name.prefix(1).uppercased())
                        .font(.title)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Circle())
                }
                Text(artist.name)
                Spacer()
                Button("Update Image") {
                    selectedArtist = artist
                    showImagePicker = true
                }
            }
        }
        .navigationTitle("Manage Artists")
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage) // Pass binding to ImagePicker
        }
        .onChange(of: selectedImage) { newImage in // Handle image upload
            if let image = newImage, let artist = selectedArtist {
                viewModel.uploadArtistImage(image, for: artist)
                selectedImage = nil // Reset after upload
            }
        }
    }
}
