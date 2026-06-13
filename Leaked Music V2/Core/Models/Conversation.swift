//
//  Conversation.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//




import FirebaseFirestore

struct Conversation: Identifiable, Codable {
    @DocumentID var id: String?
    var members: [String]
    var lastMessage: String?
    var updatedAt: Timestamp?
}

struct ChatMessage: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var senderId: String
    var text: String
    var timestamp: Timestamp

    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.senderId == rhs.senderId &&
               lhs.text == rhs.text &&
               lhs.timestamp.seconds == rhs.timestamp.seconds &&
               lhs.timestamp.nanoseconds == rhs.timestamp.nanoseconds
    }
}
