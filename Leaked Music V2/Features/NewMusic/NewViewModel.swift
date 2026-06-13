// NewViewModel.swift
// Leaked Music V2
// Created by Quinton  Thompson  on 2/23/25.

import SwiftUI
import FirebaseFirestore
import Firebase

class NewViewModel: ObservableObject {
    // Published properties used by the UI
    @Published var newAlbums: [Album] = []
    @Published var newSongs: [Song] = []
    @Published var featuredSongs: [Song] = []
    @Published var topSongs: [Song] = []
    @Published var alphabeticalArtists: [Artist] = [] // Limited to 10
    @Published var allArtists: [Artist] = []        // For "See All" view
    @Published var isLoading: Bool = true
    @Published var localError: AppError? = nil

    // Firestore snapshot listeners
    private var albumListener: ListenerRegistration?
    private var songsListener: ListenerRegistration?
    private var featuredListener: ListenerRegistration?
    private var topSongsListener: ListenerRegistration?
    private var alphabeticalArtistsListener: ListenerRegistration?
    private var allArtistsListener: ListenerRegistration?
    private var pendingInitialLoads: Set<String> = []

    // We’ll call this once (or whenever needed) to start listening
    func setupListeners() {
        guard albumListener == nil,
              songsListener == nil,
              featuredListener == nil,
              topSongsListener == nil,
              alphabeticalArtistsListener == nil else { return }

        isLoading = true
        pendingInitialLoads = ["albums", "songs", "featured", "topSongs", "artists"]

        let db = Firestore.firestore()

        // 1) New Albums
        albumListener = db.collection("albums")
            .order(by: "uploadedAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let err = error {
                    self.localError = AppError(message: "Error loading albums: \(err.localizedDescription)")
                    print("Load albums error: \(err.localizedDescription)")
                } else if let snapshot = snapshot {
                    self.newAlbums = snapshot.documents.compactMap { try? $0.data(as: Album.self) }
                    print("NewViewModel: Loaded \(self.newAlbums.count) albums")
                }
                self.markInitialLoadComplete("albums")
            }

        // 2) New Songs
        songsListener = db.collection("songs")
            .order(by: "uploadedAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let err = error {
                    self.localError = AppError(message: "Error loading songs: \(err.localizedDescription)")
                    print("Load songs error: \(err.localizedDescription)")
                } else if let snapshot = snapshot {
                    self.newSongs = snapshot.documents.compactMap { try? $0.data(as: Song.self) }
                    print("NewViewModel: Loaded \(self.newSongs.count) songs")
                }
                self.markInitialLoadComplete("songs")
            }

        // 3) Featured Songs
        featuredListener = db.collection("songs")
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "uploadedAt", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let err = error {
                    self.localError = AppError(message: "Error loading featured songs: \(err.localizedDescription)")
                    print("Load featured songs error: \(err.localizedDescription)")
                } else if let snapshot = snapshot {
                    self.featuredSongs = snapshot.documents.compactMap { try? $0.data(as: Song.self) }
                    print("NewViewModel: Loaded \(self.featuredSongs.count) featured songs")
                }
                self.markInitialLoadComplete("featured")
            }

        // 4) Top Songs
        topSongsListener = db.collection("songs")
            .order(by: "downloadCount", descending: true)
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let err = error {
                    self.localError = AppError(message: "Error loading top songs: \(err.localizedDescription)")
                    print("Load top songs error: \(err.localizedDescription)")
                } else if let snapshot = snapshot {
                    self.topSongs = snapshot.documents.compactMap { try? $0.data(as: Song.self) }
                    print("NewViewModel: Loaded \(self.topSongs.count) top songs")
                }
                self.markInitialLoadComplete("topSongs")
            }

        // 5) Alphabetical Artists (Limited)
        alphabeticalArtistsListener = db.collection("artists")
            .order(by: "name") // Assuming your Artist struct has a 'name' field
            .limit(to: 10)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let err = error {
                    self.localError = AppError(message: "Error loading artists: \(err.localizedDescription)")
                    print("Load alphabetical artists error: \(err.localizedDescription)")
                } else if let snapshot = snapshot {
                    self.alphabeticalArtists = snapshot.documents.compactMap { try? $0.data(as: Artist.self) }
                    print("NewViewModel: Loaded \(self.alphabeticalArtists.count) alphabetical artists")
                }
                self.markInitialLoadComplete("artists")
            }

    }

    func loadAllArtistsIfNeeded() {
        guard allArtistsListener == nil else { return }

        allArtistsListener = Firestore.firestore().collection("artists")
            .order(by: "name")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let err = error {
                    self.localError = AppError(message: "Error loading all artists: \(err.localizedDescription)")
                    print("Load all artists error: \(err.localizedDescription)")
                } else if let snapshot = snapshot {
                    self.allArtists = snapshot.documents.compactMap { try? $0.data(as: Artist.self) }
                    print("NewViewModel: Loaded \(self.allArtists.count) all artists")
                }
            }
    }

    private func markInitialLoadComplete(_ key: String) {
        pendingInitialLoads.remove(key)
        isLoading = !pendingInitialLoads.isEmpty
    }

    // Remove listeners when we no longer need them
    func removeListeners() {
        albumListener?.remove()
        albumListener = nil

        songsListener?.remove()
        songsListener = nil

        featuredListener?.remove()
        featuredListener = nil

        topSongsListener?.remove()
        topSongsListener = nil

        alphabeticalArtistsListener?.remove()
        alphabeticalArtistsListener = nil

        allArtistsListener?.remove()
        allArtistsListener = nil
    }

    deinit {
        // Just in case the VM goes out of scope
        removeListeners()
    }
}
