//
//  ConversationListView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ConversationListView: View {
    @StateObject private var viewModel = ConversationListViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.conversations) { conversation in
                NavigationLink(destination: EnhancedChatView(conversation: conversation)) {
                    ConversationRow(conversation: conversation)
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                viewModel.fetchConversations()
            }
            .refreshable {
                viewModel.fetchConversations()
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView("Loading Conversations...")
                    }
                }
            )
        }
    }
}

struct ConversationRow: View {
    var conversation: Conversation
    @State private var otherUserProfile: UserProfile?
    @State private var isLoadingProfile = false
    @State private var errorMessage: String?
    
    var body: some View {
        HStack {
            if isLoadingProfile {
                ProgressView()
                    .frame(width: 50, height: 50)
            } else {
                if let profile = otherUserProfile,
                   let urlString = profile.avatarURL,
                   let url = URL(string: urlString) {
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
            
            VStack(alignment: .leading) {
                if let profile = otherUserProfile {
                    Text(profile.username)
                        .font(.headline)
                } else {
                    Text("Unknown User")
                        .font(.headline)
                }
                if let lastMessage = conversation.lastMessage {
                    Text(lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            Spacer()
            if let updatedAt = conversation.updatedAt?.dateValue() {
                Text(timeAgo(updatedAt))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            loadOtherUserProfile()
        }
    }
    
    private func loadOtherUserProfile() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        // For one-on-one conversations, choose the member that is not the current user.
        guard let otherUid = conversation.members.first(where: { $0 != currentUid }) else { return }
        isLoadingProfile = true
        let db = Firestore.firestore()
        db.collection("users").document(otherUid).getDocument { snapshot, error in
            isLoadingProfile = false
            if let error = error {
                errorMessage = error.localizedDescription
            } else if let data = snapshot?.data() {
                otherUserProfile = UserProfile(data: data)
            }
        }
    }
    
    private func timeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

class ConversationListViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading: Bool = false
    
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func fetchConversations() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        listener?.remove()
        listener = db.collection("conversations")
            .whereField("members", arrayContains: currentUid)
            .order(by: "updatedAt", descending: true)
            .addSnapshotListener { snapshot, error in
                self.isLoading = false
                if let error = error {
                    print("Error fetching conversations: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    self.conversations = snapshot.documents.compactMap { doc in
                        try? doc.data(as: Conversation.self)
                    }
                }
            }
    }
    
    deinit {
        listener?.remove()
    }
}
