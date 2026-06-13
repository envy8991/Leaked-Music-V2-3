// AllArtistsView.swift
import SwiftUI

struct AllArtistsView: View {
    @ObservedObject var viewModel: NewViewModel // Or pass allArtists as binding if needed

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("All Artists")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.top)

                ArtistVerticalListView(artists: viewModel.allArtists) // Create ArtistVerticalListView below
            }
        }
        .navigationTitle("All Artists")
        .appBackground()
        .onAppear {
            // Optionally refresh all artists here if needed again
        }
    }
}

struct ArtistVerticalListView: View {
    let artists: [Artist]
    
    var body: some View {
        LazyVStack(alignment: .leading) {
            ForEach(artists, id: \.id) { artist in
                NavigationLink(destination: ArtistAlbumsView(artist: artist)) {
                    HStack {
                        if let imageURL = artist.imageURL, let url = URL(string: imageURL) {
                            CachedAsyncImage(url: url)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(artist.name.prefix(1).uppercased())
                                        .font(.headline)
                                        .foregroundColor(.white)
                                )
                        }
                        Text(artist.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                }
                Divider()
                    .background(Color.gray.opacity(0.4))
                    .padding(.leading, 60)
            }
        }
    }
}
