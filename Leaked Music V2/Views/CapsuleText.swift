//
//  CapsuleText.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/20/25.
//


import SwiftUI

struct CapsuleText: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .foregroundColor(.white)
            .background(color)
            .clipShape(Capsule())
    }
}