//
//  ToastModifier.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/12/25.
//


import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: String?
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if let message = message {
                VStack {
                    Spacer()
                    Text(message)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .transition(.move(edge: .bottom))
                }
                .padding()
            }
        }
    }
}

extension View {
    func toast(message: Binding<String?>) -> some View {
        self.modifier(ToastModifier(message: message))
    }
}