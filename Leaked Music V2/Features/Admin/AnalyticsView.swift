//
//  AnalyticsView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//


import SwiftUI

struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Active Users: \(viewModel.activeUserCount)")
                        Text("Total Users: \(viewModel.totalUserCount)")
                    }
                    .font(.headline)
                    
                    Divider()
                    
                    Text("Top 10 Most Popular Songs")
                        .font(.title2)
                        .bold()
                    
                    ForEach(viewModel.topSongs, id: \.id) { song in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(song.title)
                                .font(.headline)
                            Text("Downloads: \(song.downloadCount)")
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("Analytics")
            .alert(item: Binding(get: {
                viewModel.errorMessage.map { AppError(message: $0) }
            }, set: { _ in
                viewModel.errorMessage = nil
            })) { error in
                Alert(title: Text("Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
}