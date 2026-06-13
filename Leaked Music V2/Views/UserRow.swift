import SwiftUI

struct UserRow: View {
    var user: UserProfile

    var body: some View {
        HStack {
            if let avatarURL = user.avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else if phase.error != nil {
                        Circle().fill(Color.gray.opacity(0.3))
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle().fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }
            VStack(alignment: .leading) {
                Text(user.username).font(.headline)
                if let lastPlayed = user.lastPlayedSongTitle {
                    Text("Last Played: \(lastPlayed)") // Changed text to "Last Played"
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
