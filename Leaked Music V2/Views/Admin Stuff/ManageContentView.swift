import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct ManageContentView: View {
    @State private var artists: [Artist] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading...")
                        .padding()
                } else {
                    List {
                        ForEach(artists) { artist in
                            NavigationLink(destination: ArtistManageView(artist: artist)) {
                                Text(artist.name)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Content")
            .onAppear(perform: loadArtists)
            .alert(item: $localError) { error in
                Alert(title: Text("Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK"), action: { localError = nil }))
            }
            .appBackground() // Your custom background modifier, if any
        }
    }

    private func loadArtists() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("artists").getDocuments { snapshot, error in
            if let error = error {
                localError = AppError(message: "Error loading artists: \(error.localizedDescription)")
                Logger.log("Load all artists error", error: error)
            } else if let docs = snapshot?.documents {
                artists = docs.compactMap { try? $0.data(as: Artist.self) }
            }
            isLoading = false
        }
    }
}
