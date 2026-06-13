// ArtistListView.swift
import SwiftUI

struct ArtistListView: View {
    let artists: [Artist]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) { // Horizontal scroll for Artists
            HStack(spacing: 20) {
                ForEach(artists, id: \.id) { artist in // Assuming Artist struct has an 'id'
                    NavigationLink(destination: ArtistAlbumsView(artist: artist)) {
                        ArtistCardView(artist: artist) // Create ArtistCardView below
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

struct ArtistCardView: View {
    let artist: Artist
    
    var body: some View {
        VStack {
            if let imageURL = artist.imageURL, let url = URL(string: imageURL) {
                CachedAsyncImage(url: url)
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text(artist.name.prefix(1).uppercased())
                            .font(.title)
                            .foregroundColor(.white)
                    )
            }
            Text(artist.name)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(width: 100)
    }
}
