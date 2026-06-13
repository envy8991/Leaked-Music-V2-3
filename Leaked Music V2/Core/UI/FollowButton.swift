//
//  FollowButton.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/13/25.
//


// FollowButton.swift
import SwiftUI

struct FollowButton: View {
    var targetUserId: String
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        Button(action: {
            if session.following.contains(targetUserId) {
                session.unfollowUser(targetUserId)
            } else {
                session.followUser(targetUserId)
            }
        }) {
            Text(session.following.contains(targetUserId) ? "Unfollow" : "Follow")
                .padding(8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
        }
    }
}