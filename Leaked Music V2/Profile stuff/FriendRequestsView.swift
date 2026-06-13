import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendRequestsView: View {
    @StateObject private var viewModel = FriendRequestsViewModel()
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading Friend Requests...")
                        Spacer()
                    }
                } else if viewModel.requests.isEmpty {
                    Text("No pending friend requests.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(viewModel.requests) { request in
                        FriendRequestRow(request: request)
                    }
                }
            }
            .navigationTitle("Friend Requests")
            .onAppear {
                viewModel.fetchFriendRequests()
            }
            .refreshable {
                viewModel.fetchFriendRequests()
            }
        }
    }
}

struct FriendRequestRow: View {
    var request: FriendRequest
    @EnvironmentObject var session: SessionStore
    @State private var senderName: String = ""
    @State private var senderAvatarURL: String = ""
    @State private var isLoadingData = false
    @State private var isProcessing = false
    @State private var errorWrapper: ErrorWrapper? = nil
    @State private var showAcceptedToast = false

    var body: some View {
        HStack {
            // Sender's Avatar
            if isLoadingData {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                if let url = URL(string: senderAvatarURL), !senderAvatarURL.isEmpty {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                        } else if phase.error != nil {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.gray)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                }
            }
            
            // Sender's Name
            Text("From: \(senderName.isEmpty ? request.from : senderName)")
                .font(.headline)
            
            Spacer()
            
            if isProcessing {
                ProgressView()
            } else {
                Button("Accept") {
                    acceptRequest()
                }
                .buttonStyle(BorderlessButtonStyle())
                .padding(.trailing, 8)
                Button("Decline") {
                    declineRequest()
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .onAppear {
            fetchSenderData()
        }
        .alert(item: $errorWrapper) { wrapper in
            Alert(title: Text("Error"), message: Text(wrapper.message), dismissButton: .default(Text("OK")))
        }
        .overlay(
            Group {
                if showAcceptedToast {
                    Text("Friend Request Accepted")
                        .padding(8)
                        .background(Color.green.opacity(0.8))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .transition(.opacity)
                }
            }, alignment: .top
        )
    }
    
    private func fetchSenderData() {
        guard !request.from.isEmpty else { return }
        isLoadingData = true
        let db = Firestore.firestore()
        db.collection("users").document(request.from).getDocument { snapshot, error in
            isLoadingData = false
            if let error = error {
                errorWrapper = ErrorWrapper(message: error.localizedDescription)
            } else if let data = snapshot?.data() {
                let profile = UserProfile(data: data)
                senderName = profile.username
                senderAvatarURL = profile.avatarURL ?? ""
            }
        }
    }
    
    private func acceptRequest() {
        isProcessing = true
        session.acceptFriendRequest(requestId: request.id ?? "", from: request.from) { error in
            isProcessing = false
            if let error = error {
                errorWrapper = ErrorWrapper(message: error.localizedDescription)
            } else {
                withAnimation {
                    showAcceptedToast = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        showAcceptedToast = false
                    }
                }
            }
        }
    }
    
    private func declineRequest() {
        guard let requestId = request.id else { return }
        isProcessing = true
        let db = Firestore.firestore()
        db.collection("friendRequests").document(requestId).delete { error in
            isProcessing = false
            if let error = error {
                errorWrapper = ErrorWrapper(message: error.localizedDescription)
            }
        }
    }
}

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    var from: String
    var to: String
    var timestamp: Timestamp
    var status: String
}

class FriendRequestsViewModel: ObservableObject {
    @Published var requests: [FriendRequest] = []
    @Published var isLoading: Bool = false
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func fetchFriendRequests() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        listener?.remove()
        listener = db.collection("friendRequests")
            .whereField("to", isEqualTo: currentUid)
            .whereField("status", isEqualTo: "pending")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                if let error = error {
                    print("Error fetching friend requests: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    self.requests = snapshot.documents.compactMap { doc in
                        try? doc.data(as: FriendRequest.self)
                    }
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
