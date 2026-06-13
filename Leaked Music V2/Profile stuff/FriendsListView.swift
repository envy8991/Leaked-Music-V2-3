//
//  FriendsListView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct FriendsListView: View {
    @EnvironmentObject var session: SessionStore
    @State private var friends: [UserProfile] = []
    @State private var isLoading = false
    @State private var errorWrapper: ErrorWrapper?

    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading Friends...")
                        Spacer()
                    }
                } else if friends.isEmpty {
                    Text("You have no friends yet.")
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(friends) { friend in
                        NavigationLink(destination: UserProfileView(user: friend).environmentObject(session)) {
                            HStack {
                                if let avatarURL = friend.avatarURL,
                                   let url = URL(string: avatarURL) {
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image.resizable()
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
                                Text(friend.username)
                                    .font(.headline)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Friends")
            .onAppear {
                loadFriends()
            }
            .alert(item: $errorWrapper) { wrapper in
                Alert(title: Text("Error"),
                      message: Text(wrapper.message),
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func loadFriends() {
        guard let currentUid = session.currentUser?.uid else { return }
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users").document(currentUid).collection("friends")
            .getDocuments { snapshot, error in
                if let error = error {
                    errorWrapper = ErrorWrapper(message: error.localizedDescription)
                    isLoading = false
                    return
                }
                guard let documents = snapshot?.documents else {
                    isLoading = false
                    return
                }
                let friendIDs = documents.map { $0.documentID }
                fetchFriendProfiles(friendIDs: friendIDs)
            }
    }
    
    private func fetchFriendProfiles(friendIDs: [String]) {
        let db = Firestore.firestore()
        var loadedFriends: [UserProfile] = []
        let group = DispatchGroup()
        
        for friendId in friendIDs {
            group.enter()
            db.collection("users").document(friendId).getDocument { snapshot, error in
                if let data = snapshot?.data() {
                    let profile = UserProfile(data: data)
                    loadedFriends.append(profile)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            friends = loadedFriends
            isLoading = false
        }
    }
}