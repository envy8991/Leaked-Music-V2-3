//
//  NotificationView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/13/25.
//


import SwiftUI
import FirebaseFirestore

struct NotificationView: View {
    @State private var notifications: [AppNotification] = []
    @State private var localError: AppError? = nil
    @State private var listener: ListenerRegistration?
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        NavigationView {
            List(notifications) { notification in
                VStack(alignment: .leading) {
                    Text(notification.message)
                    Text(notification.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Notifications")
            .onAppear(perform: fetchNotifications)
            .onDisappear { listener?.remove() }
            .alert(item: $localError) {
                Alert(title: Text("Error"),
                      message: Text($0.message),
                      dismissButton: .default(Text("OK")))
            }
            .appBackground()
        }
    }
    
    private func fetchNotifications() {
        guard let uid = session.currentUser?.uid else { return }
        let db = Firestore.firestore()
        listener = db.collection("notifications")
            .whereField("userId", isEqualTo: uid)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    localError = AppError(message: error.localizedDescription)
                } else if let snapshot = snapshot {
                    notifications = snapshot.documents.compactMap { try? $0.data(as: AppNotification.self) }
                }
            }
    }
}
