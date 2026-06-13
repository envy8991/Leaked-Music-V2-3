//
//  AnalyticsViewModel.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//


import SwiftUI
import FirebaseFirestore

// MARK: - Analytics View Model

class AnalyticsViewModel: ObservableObject {
    @Published var activeUserCount: Int = 0
    @Published var totalUserCount: Int = 0
    @Published var topSongs: [Song] = []
    @Published var errorMessage: String? = nil

    private var db = Firestore.firestore()
    private var activeUsersListener: ListenerRegistration? = nil

    init() {
        fetchTotalUserCount()
        listenForActiveUsers()
        fetchTopSongs()
    }

    deinit {
        activeUsersListener?.remove()
    }

    /// Listen in real time for active users
    func listenForActiveUsers() {
        activeUsersListener = db.collection("users")
            .whereField("isOnline", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "Error fetching active users: \(error.localizedDescription)"
                    return
                }
                self?.activeUserCount = snapshot?.documents.count ?? 0
            }
    }

    /// Fetch total number of users (one‑time fetch)
    func fetchTotalUserCount() {
        db.collection("users").getDocuments { [weak self] snapshot, error in
            if let error = error {
                self?.errorMessage = "Error fetching total users: \(error.localizedDescription)"
                return
            }
            self?.totalUserCount = snapshot?.documents.count ?? 0
        }
    }

    /// Fetch the top 10 songs ordered by downloadCount descending
    func fetchTopSongs() {
        db.collection("songs")
            .order(by: "downloadCount", descending: true)
            .limit(to: 10)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    self?.errorMessage = "Error fetching top songs: \(error.localizedDescription)"
                    return
                }
                self?.topSongs = snapshot?.documents.compactMap { try? $0.data(as: Song.self) } ?? []
            }
    }
}

