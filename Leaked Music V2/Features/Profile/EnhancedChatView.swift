//
//  EnhancedChatView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct EnhancedChatView: View {
    let conversation: Conversation
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var isLoading = false
    @State private var messageListener: ListenerRegistration?
    
    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack {
                        ForEach(messages) { message in
                            ChatBubble(message: message, isCurrentUser: message.senderId == Auth.auth().currentUser?.uid)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.last?.id) { lastMessageId in
                    guard let lastMessageId = lastMessageId else { return }
                    DispatchQueue.main.async {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessageId, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Message", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: sendMessage) {
                    Text("Send")
                        .bold()
                }
                .disabled(newMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMessages()
        }
        .onDisappear {
            messageListener?.remove()
            messageListener = nil
        }
    }
    
    private func loadMessages() {
        guard messageListener == nil, let conversationId = conversation.id else { return }
        isLoading = true
        let db = Firestore.firestore()
        messageListener = db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                isLoading = false
                if let error = error {
                    print("Error loading messages: \(error.localizedDescription)")
                } else if let snapshot = snapshot {
                    messages = snapshot.documents.compactMap { doc in
                        try? doc.data(as: ChatMessage.self)
                    }
                }
            }
    }
    
    private func sendMessage() {
        let trimmed = newMessage.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let db = Firestore.firestore()
        guard let convoId = conversation.id else { return }
        let currentUserId = Auth.auth().currentUser?.uid ?? ""
        let messageData: [String: Any] = [
            "senderId": currentUserId,
            "text": trimmed,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("conversations").document(convoId)
            .collection("messages").addDocument(data: messageData) { error in
                if let error = error {
                    print("Error sending message: \(error.localizedDescription)")
                } else {
                    newMessage = ""
                    db.collection("conversations").document(convoId).updateData([
                        "lastMessage": trimmed,
                        "updatedAt": Timestamp(date: Date())
                    ])
                }
            }
    }
}