//
//  ChatBubble.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/14/25.
//


import SwiftUI

struct ChatBubble: View {
    var message: ChatMessage
    var isCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isCurrentUser {
                Spacer()
                Text(message.text)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .padding(.leading, 60)
            } else {
                Text(message.text)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .padding(.trailing, 60)
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}