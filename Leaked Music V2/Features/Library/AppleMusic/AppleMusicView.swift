//
//  AppleMusicView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/21/25.
//


import SwiftUI
import MusicKit

struct AppleMusicView: View {
    @State private var musicAuthorizationStatus: MusicAuthorization.Status = .notDetermined

    var body: some View {
        NavigationView {
            VStack {
                switch musicAuthorizationStatus {
                case .authorized:
                    // User is authorized, show Apple Music content
                    appleMusicContentView()
                case .denied, .restricted:
                    // User denied or restricted access, display message
                    Text("Apple Music access denied. Please grant access in Settings.")
                        .padding()
                case .notDetermined:
                    // Authorization not yet requested, request it on appear
                    Text("Requesting Apple Music access...")
                        .padding()
                default:
                    Text("Unknown authorization status.")
                        .padding()
                }
            }
            .navigationTitle("Apple Music")
            .onAppear {
                checkMusicAuthorization()
            }
        }
    }

    private func checkMusicAuthorization() {
        Task {
            musicAuthorizationStatus = await MusicAuthorization.request()
        }
    }

    @ViewBuilder
    private func appleMusicContentView() -> some View {
        List {
            Section(header: Text("Apple Music Library")) {
                NavigationLink("Playlists", destination: AppleMusicPlaylistsView())
                NavigationLink("Artists", destination: AppleMusicArtistsView())
                NavigationLink("Albums", destination: AppleMusicAlbumsView())
                NavigationLink("Songs", destination: AppleMusicSongsView())
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}
