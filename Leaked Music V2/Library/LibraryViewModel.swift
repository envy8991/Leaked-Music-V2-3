import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

class LibraryViewModel: ObservableObject {
    @Published var recentlyAddedAlbums: [Album] = []
    @Published var isLoading = false
    @Published var localError: AppError? = nil

    private var libraryAlbumsListener: ListenerRegistration?

    // Start listening to the user's libraryAlbums - RESTORED to libraryAlbums
    func setupListener() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        isLoading = true

        let db = Firestore.firestore()
        libraryAlbumsListener = db.collection("users")
            .document(uid)
            .collection("libraryAlbums") // <-- RESTORED: Listening to 'libraryAlbums' collection
            .order(by: "dateAdded", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let err = error {
                    self.localError = AppError(message: "Error loading library albums: \(err.localizedDescription)") // RESTORED error message
                    self.isLoading = false
                    return
                }

                // Parse references (the doc IDs or fields you use to find the global album docs)
                guard let docs = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                let albumRefs = docs.compactMap { try? $0.data(as: LibraryAlbumRef.self) }

                // Now fetch the *actual* albums from the global "albums" collection
                self.loadGlobalAlbums(for: albumRefs) { // RESTORED: loadGlobalAlbums function
                    self.isLoading = false
                }
            }
    }

    // Remove the listener when not needed
    func removeListener() {
        libraryAlbumsListener?.remove()
        libraryAlbumsListener = nil
    }

    /// Looks up each referenced album doc in the main "albums" collection,
    /// then sets `recentlyAddedAlbums` sorted by `uploadedAt`. - RESTORED function
    private func loadGlobalAlbums(for refs: [LibraryAlbumRef], completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        var fetched: [Album] = []

        let group = DispatchGroup()
        for ref in refs {
            group.enter()
            db.collection("albums").document(ref.albumId).getDocument { snap, err in
                defer { group.leave() }
                if let snap = snap, snap.exists,
                   let album = try? snap.data(as: Album.self) {
                    fetched.append(album)
                }
            }
        }

        group.notify(queue: .main) {
            // Sort them by 'uploadedAt'
            fetched.sort {
                ($0.uploadedAt?.dateValue() ?? Date()) >
                ($1.uploadedAt?.dateValue() ?? Date())
            }
            self.recentlyAddedAlbums = fetched
            completion()
        }
    }

    deinit {
        // In case the VM is deallocated
        removeListener()
    }
}
