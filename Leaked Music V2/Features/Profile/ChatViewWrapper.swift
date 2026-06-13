//
//  ChatViewWrapper.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChatViewWrapper: View {
    @EnvironmentObject var session: SessionStore
    var targetUser: UserProfile
    @State private var conversation: Conversation?
    @State private var isLoading = true
    @State private var errorWrapper: ErrorWrapper?

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading conversation...")
            } else if let conversation = conversation {
                EnhancedChatView(conversation: conversation)
            } else if let errorWrapper = errorWrapper {
                Text("Error: \(errorWrapper.message)")
                    .foregroundColor(.red)
            } else {
                Text("No conversation found.")
            }
        }
        .onAppear {
            startConversation()
        }
    }
    
    private func startConversation() {
        guard let currentUid = session.currentUser?.uid else {
            errorWrapper = ErrorWrapper(message: "User not logged in.")
            isLoading = false
            return
        }
        let db = Firestore.firestore()
        db.collection("conversations")
            .whereField("members", arrayContains: currentUid)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorWrapper = ErrorWrapper(message: error.localizedDescription)
                    isLoading = false
                    return
                }
                if let docs = snapshot?.documents {
                    // Look for a conversation that includes both the current user and target user.
                    for doc in docs {
                        if let convo = try? doc.data(as: Conversation.self),
                           convo.members.contains(targetUser.uid) {
                            conversation = convo
                            isLoading = false
                            return
                        }
                    }
                }
                // No existing conversation found; create one.
                let newConvoRef = db.collection("conversations").document()
                let newConvo = Conversation(id: newConvoRef.documentID,
                                            members: [currentUid, targetUser.uid],
                                            lastMessage: nil,
                                            updatedAt: Timestamp(date: Date()))
                do {
                    try newConvoRef.setData(from: newConvo) { error in
                        if let error = error {
                            errorWrapper = ErrorWrapper(message: error.localizedDescription)
                        } else {
                            conversation = newConvo
                        }
                        isLoading = false
                    }
                } catch {
                    errorWrapper = ErrorWrapper(message: error.localizedDescription)
                    isLoading = false
                }
            }
    }
}