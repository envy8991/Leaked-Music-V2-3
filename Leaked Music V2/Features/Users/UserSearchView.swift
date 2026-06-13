import SwiftUI
import FirebaseFirestore

struct UserSearchView: View {
    @EnvironmentObject var session: SessionStore
    @State private var searchText = ""
    @State private var searchResults: [UserProfile] = []
    @State private var isLoading = false
    @State private var localError: AppError? = nil
    @State private var debounceWorkItem: DispatchWorkItem?
    
    var body: some View {
        VStack {
            TextField("Search Users by username", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .onChange(of: searchText) { newValue in
                    debounceWorkItem?.cancel()
                    let workItem = DispatchWorkItem { performSearch(with: newValue) }
                    debounceWorkItem = workItem
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
                }
            if isLoading {
                ProgressView("Searching...")
            } else {
                List(searchResults, id: \.uid) { user in
                    NavigationLink(destination: UserProfileView(user: user)) {
                        UserRow(user: user)
                    }
                }
            }
        }
        .navigationTitle("User Search")
        .alert(item: $localError) {
            Alert(title: Text("Error"), message: Text($0.message), dismissButton: .default(Text("OK")))
        }
        .appBackground()
    }
    
    private func performSearch(with query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { searchResults = []; return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users")
            .order(by: "username")
            .start(at: [trimmed])
            .end(at: [trimmed + "\u{f8ff}"])
            .getDocuments { snapshot, error in
                if let error = error {
                    localError = AppError(message: "User search failed: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    searchResults = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
                }
                isLoading = false
            }
    }
}
