import SwiftUI
import FirebaseFirestore

// Extend the Comment model to support threaded replies.
struct Comment: Identifiable, Codable {
    var id: String
    var contentID: String  // The ID of the song or playlist being commented on.
    var userID: String
    var username: String
    var text: String
    var timestamp: Date
    var parentCommentID: String? = nil  // nil for top-level comments.
}

struct CommentsView: View {
    var contentID: String
    @EnvironmentObject var session: SessionStore
    @State private var comments: [Comment] = []
    @State private var newComment: String = ""
    @State private var localError: AppError? = nil
    @State private var listener: ListenerRegistration?
    @State private var replyForComment: Comment? = nil
    @State private var replyText: String = ""
    
    var body: some View {
        VStack {
            List {
                // Display top-level comments.
                ForEach(comments.filter { $0.parentCommentID == nil }) { comment in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(comment.username)
                                .fontWeight(.bold)
                            Text(comment.timestamp, style: .time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(comment.text)
                        HStack {
                            Button("Reply") {
                                withAnimation { replyForComment = comment }
                            }
                            Spacer()
                            CommentLikeButton(comment: comment)
                        }
                        // Display replies (threaded comments) indented.
                        ForEach(comments.filter { $0.parentCommentID == comment.id }) { reply in
                            HStack {
                                Spacer().frame(width: 20)
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(reply.username)
                                            .fontWeight(.bold)
                                        Text(reply.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(reply.text)
                                    HStack {
                                        Button("Reply") {
                                            withAnimation { replyForComment = reply }
                                        }
                                        Spacer()
                                        CommentLikeButton(comment: reply)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            // Show reply field if replying; otherwise, show new comment field.
            if let replying = replyForComment {
                VStack {
                    Text("Replying to \(replying.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        TextField("Your reply...", text: $replyText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Send") {
                            postReply(for: replying)
                        }
                    }
                }
                .padding()
            } else {
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Send") { postComment() }
                }
                .padding()
            }
        }
        .navigationTitle("Comments")
        .onAppear(perform: setupListener)
        .onDisappear { listener?.remove() }
        .alert(item: $localError) {
            Alert(title: Text("Error"),
                  message: Text($0.message),
                  dismissButton: .default(Text("OK")))
        }
        .appBackground()
    }
    
    private func setupListener() {
        let db = Firestore.firestore()
        listener = db.collection("comments")
            .whereField("contentID", isEqualTo: contentID)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else if let snapshot = snapshot {
                    comments = snapshot.documents.compactMap { try? $0.data(as: Comment.self) }
                }
            }
    }
    
    private func postComment() {
        guard !newComment.isEmpty, let user = session.currentUser else { return }
        let db = Firestore.firestore()
        let commentData: [String: Any] = [
            "id": UUID().uuidString,
            "contentID": contentID,
            "userID": user.uid,
            "username": user.username,
            "text": newComment,
            "timestamp": Timestamp(date: Date())
        ]
        db.collection("comments").addDocument(data: commentData) { error in
            if let error = error {
                localError = AppError(message: error.localizedDescription)
            } else {
                newComment = ""
            }
        }
    }
    
    private func postReply(for comment: Comment) {
        guard !replyText.isEmpty, let user = session.currentUser else { return }
        let db = Firestore.firestore()
        let replyData: [String: Any] = [
            "id": UUID().uuidString,
            "contentID": contentID,
            "userID": user.uid,
            "username": user.username,
            "text": replyText,
            "timestamp": Timestamp(date: Date()),
            "parentCommentID": comment.id
        ]
        db.collection("comments").addDocument(data: replyData) { error in
            if let error = error {
                localError = AppError(message: error.localizedDescription)
            } else {
                replyText = ""
                replyForComment = nil
            }
        }
    }
}

// Helper view for liking comments.
struct CommentLikeButton: View {
    var comment: Comment
    @EnvironmentObject var session: SessionStore
    @State private var userLiked: Bool = false
    @State private var localError: AppError? = nil
    
    var body: some View {
        Button(action: toggleLike) {
            Image(systemName: userLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                .foregroundColor(.blue)
        }
        .onAppear(perform: fetchLikes)
        .alert(item: $localError) {
            Alert(title: Text("Error"),
                  message: Text($0.message),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    private func fetchLikes() {
        guard let commentId = comment.id as String? else { return }
        let db = Firestore.firestore()
        db.collection("comments").document(commentId).collection("likes")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else if let snapshot = snapshot {
                    if let user = session.currentUser {
                        userLiked = snapshot.documents.contains { $0.documentID == user.uid }
                    }
                }
            }
    }
    
    private func toggleLike() {
        guard let commentId = comment.id as String?, let user = session.currentUser else { return }
        let db = Firestore.firestore()
        let likeRef = db.collection("comments").document(commentId).collection("likes").document(user.uid)
        if userLiked {
            likeRef.delete { error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else {
                    userLiked = false
                }
            }
        } else {
            likeRef.setData(["liked": true]) { error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else {
                    userLiked = true
                }
            }
        }
    }
}
