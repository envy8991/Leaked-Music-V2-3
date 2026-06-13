import SwiftUI
import FirebaseFirestore

struct RecommendationsView: View {
    @State private var recommendedSongs: [Song] = []
    @State private var localError: AppError? = nil
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Recommendations...")
                } else {
                    List(recommendedSongs) { song in
                        SongRow(originalSong: song, showAddButton: true)
                    }
                }
            }
            .navigationTitle("Recommended")
            .onAppear(perform: loadRecommendations)
            .alert(item: $localError) {
                Alert(title: Text("Error"),
                      message: Text($0.message),
                      dismissButton: .default(Text("OK")))
            }
            .appBackground()
        }
    }
    
    func loadRecommendations() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("songs")
            .order(by: "downloadCount", descending: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else if let snapshot = snapshot {
                    recommendedSongs = snapshot.documents.compactMap { try? $0.data(as: Song.self) }
                }
                isLoading = false
            }
    }
}
