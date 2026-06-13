//
//  AppleMusicArtistsView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/21/25.
//


import SwiftUI
import MusicKit

struct AppleMusicArtistsView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.pink, Color.purple, Color.blue]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            Text("Apple Music Artists")
                .foregroundColor(.white)
        }
        .navigationTitle("Apple Music Artists")
    }
}
