import SwiftUI
import FirebaseFirestore

struct ManageUsersView: View {
    @State private var users: [UserProfile] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading Users...")
                        .padding()
                } else if let errorMessage = errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    List {
                        ForEach(users) { user in
                            ManageUserRowView(user: user) { updatedUser in
                                if let index = users.firstIndex(where: { $0.uid == updatedUser.uid }) {
                                    users[index] = updatedUser
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Manage Users")
            .toolbar {
                Button("Refresh") {
                    fetchUsers()
                }
            }
            .onAppear {
                fetchUsers()
            }
        }
    }
    
    private func fetchUsers() {
        isLoading = true
        errorMessage = nil
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            isLoading = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let snapshot = snapshot {
                self.users = snapshot.documents.compactMap { doc in
                    try? doc.data(as: UserProfile.self)
                }
            }
        }
    }
}
