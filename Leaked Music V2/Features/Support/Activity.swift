import SwiftUI
import FirebaseFirestore

struct Activity: Identifiable, Codable {
    var id: String
    var userID: String
    var username: String
    var action: String
    var timestamp: Date
}

struct ActivityFeedView: View {
    @State private var activities: [Activity] = []
    @State private var localError: AppError? = nil
    @State private var listener: ListenerRegistration?
    
    var body: some View {
        NavigationView {
            List(activities) { activity in
                HStack {
                    Text(activity.username)
                        .fontWeight(.bold)
                    Text(activity.action)
                    Spacer()
                    Text(activity.timestamp, style: .time)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Activity Feed")
            .onAppear(perform: setupListener)
            .onDisappear { listener?.remove() }
            .alert(item: $localError) {
                Alert(title: Text("Error"), message: Text($0.message), dismissButton: .default(Text("OK")))
            }
            .appBackground()
        }
    }
    
    private func setupListener() {
        let db = Firestore.firestore()
        listener = db.collection("activityFeed")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else if let snapshot = snapshot {
                    activities = snapshot.documents.compactMap { try? $0.data(as: Activity.self) }
                }
            }
    }
}
