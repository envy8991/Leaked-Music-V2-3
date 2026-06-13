//
//  SongDetailView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/18/25.
//


import SwiftUI

struct SongDetailView: View {
    let song: Song
    
    var body: some View {
        VStack(spacing: 20) {
            Text(song.title)
                .font(.largeTitle)
                .bold()
            Text("by \(song.artist)")
                .font(.title2)
                .foregroundColor(.secondary)
            // Additional details or playback controls can be added here.
            Spacer()
        }
        .padding()
        .navigationTitle("Song Detail")
    }
}