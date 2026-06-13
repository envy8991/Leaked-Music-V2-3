//
//  SubscriptionView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/19/25.
//


//
//  SubscriptionView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/19/25.
//

import SwiftUI

struct SubscriptionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: SessionStore // Import SessionStore environment object

    var body: some View {
        NavigationView {
            VStack {
                Text("Unlock Premium Features")
                    .font(.title)
                    .padding()

                Text("Subscribe to get access to all premium features of our app!")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Link("Subscribe Now", destination: URL(string: "https://buy.stripe.com/aEU7uV4dqebm3RK5kk")!)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.top, 20)

                // Add the instructional message
                Text("After you have paid, I will approve your account. Join our Discord and let me know you’ve paid, in the 'paid comment here channel' under the feedback category, simply comment 'paid'.")
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                // Add the Discord button
                Link("Join Discord", destination: URL(string: "https://discord.gg/YZkJ9BRf")!)
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appBackground()
            .navigationTitle("Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        session.signOut() // Call session.signOut() to go back to AuthView
                        dismiss() // Still dismiss the SubscriptionView for proper cleanup
                    }
                }
            }
        }
    }
}
