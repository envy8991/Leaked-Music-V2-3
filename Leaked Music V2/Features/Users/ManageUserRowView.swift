//
//  ManageUserRowView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/25/25.
//


import SwiftUI
import FirebaseFirestore

struct ManageUserRowView: View {
    @State var user: UserProfile
    var onUpdate: ((UserProfile) -> Void)? = nil

    var body: some View {
        HStack(spacing: 16) {
            Text(user.username)
                .font(.headline)
            
            Spacer()
            
            // "Paid" status toggle with label
            VStack(spacing: 4) {
                Text("Paid")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Toggle("", isOn: $user.isPaid)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: user.isPaid) { newValue in
                        updateField(field: "isPaid", value: newValue)
                    }
            }
            
            // "Admin" status toggle with label
            VStack(spacing: 4) {
                Text("Admin")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Toggle("", isOn: $user.isAdmin)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .blue))
                    .onChange(of: user.isAdmin) { newValue in
                        updateField(field: "isAdmin", value: newValue)
                    }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func updateField(field: String, value: Bool) {
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).updateData([field: value]) { error in
            if let error = error {
                print("Error updating \(field) for \(user.username): \(error.localizedDescription)")
            } else {
                onUpdate?(user)
            }
        }
    }
}
