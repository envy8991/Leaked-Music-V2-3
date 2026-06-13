//
//  SongEditView.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 3/13/25.
//


import SwiftUI
import FirebaseFirestore

struct SongEditView: View {
    @State var song: Song
    let album: Album
    @State private var updatedTitle: String = ""
    @State private var localError: AppError? = nil
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        Form {
            Section(header: Text("Song Details")) {
                TextField("Song Title", text: $updatedTitle)
            }
            Section {
                Button("Save Changes") {
                    updateSong()
                }
            }
        }
        .navigationTitle("Edit Song")
        .onAppear {
            updatedTitle = song.title
        }
        .alert(item: $localError) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK")))
        }
    }

    private func updateSong() {
        guard let songId = song.id else { return }
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "title": updatedTitle,
            "title_lower": updatedTitle.lowercased()
        ]
        db.collection("songs").document(songId).updateData(data) { error in
            if let error = error {
                localError = AppError(message: "Error updating song: \(error.localizedDescription)")
            } else {
                song.title = updatedTitle
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}