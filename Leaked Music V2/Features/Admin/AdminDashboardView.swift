import SwiftUI
import FirebaseFirestore

struct AdminDashboardView: View {
    @State private var topSongs: [Song] = []
    @State private var activeUserCount: Int = 0
    @State private var localError: AppError? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading Analytics...")
                } else {
                    Text("Active Users: \(activeUserCount)")
                        .font(.title)
                        .padding()
                    
                    Text("Most Played Songs")
                        .font(.headline)
                    List(topSongs) { song in
                        HStack {
                            Text(song.title)
                            Spacer()
                            Text("\(song.downloadCount) plays")
                        }
                    }
                }
                Spacer()
            }
            .navigationTitle("Admin Dashboard")
            .onAppear(perform: loadAnalytics)
            .alert(item: $localError) {
                Alert(title: Text("Error"), message: Text($0.message), dismissButton: .default(Text("OK")))
            }
            .appBackground()
        }
    }
    
    private func loadAnalytics() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("songs")
            .order(by: "downloadCount", descending: true)
            .limit(to: 5)
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else if let snapshot = snapshot {
                    topSongs = snapshot.documents.compactMap { try? $0.data(as: Song.self) }
                }
                isLoading = false
            }
        db.collection("users")
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    activeUserCount = snapshot.documents.count
                }
            }
    }
}
