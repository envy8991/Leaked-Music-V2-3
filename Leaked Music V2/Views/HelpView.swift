import SwiftUI

struct HelpView: View {
 @State private var showOnboardingView = false // State for presenting OnboardingView

 var body: some View {
 NavigationView {
 List {
 // Onboarding Section
 Section(header: Text("Onboarding")) {
 Button(action: { showOnboardingView = true }) {
 Label("Show Onboarding Guide", systemImage: "book.circle")
 .foregroundColor(.blue)
 }
 }

 // Using the App Section
 Section(header: Text("Using the App")) {
 NavigationLink(destination: WelcomeView()) {
 Label("Welcome to Leaked Music", systemImage: "music.note.list")
 }
 NavigationLink(destination: PremiumFeaturesView()) {
 Label("Unlock Premium Features", systemImage: "crown.fill")
 }
 NavigationLink(destination: CreatePlaylistView()) {
 Label("Creating Playlists", systemImage: "ellipsis.circle")
 }
 NavigationLink(destination: DownloadSongsView()) {
 Label("Downloading Songs", systemImage: "arrow.down.circle")
 }
 NavigationLink(destination: AlbumDetailsView()) {
 Label("View Album Details", systemImage: "rectangle.stack")
 }
 NavigationLink(destination: DiscoverMusicView()) {
 Label("Discover New Music", systemImage: "sparkles")
 }
 NavigationLink(destination: ConnectOthersView()) {
 Label("Connect with Others", systemImage: "person.2.fill")
 }
 NavigationLink(destination: CustomizeProfileView()) {
 Label("Customize Your Profile", systemImage: "person.crop.circle.fill.badge.checkmark")
 }
 }


 // Support Section
 Section(header: Text("Support")) {
 Link(destination: URL(string: "https://discord.gg/zVXrU4UAzP")!) {
 Label("Join Our Discord", systemImage: "bubble.left.and.bubble.right")
 .foregroundColor(.blue)
 }
 }
 }
 .navigationTitle("Help & Support")
 .appBackground()
 .sheet(isPresented: $showOnboardingView) {
 OnboardingView(isPresented: $showOnboardingView)
 }
 }
 }
}

// Extracted Detail Views
struct WelcomeView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "music.note.list")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.purple)
 Text("Welcome to Leaked Music")
 .font(.title2)
 .bold()
 Text("Discover, listen, and share music like never before!")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 }
 .padding()
 }
}

struct PremiumFeaturesView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "crown.fill")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.yellow)
 Text("Unlock Premium Features")
 .font(.title2)
 .bold()
 Text("Subscribe to Premium and unlock exclusive capabilities, including uploading your own music to your Personal Library!")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 Text("Support the app and grow your music collection.")
 .multilineTextAlignment(.center)
 .foregroundColor(.gray)
 }
 .padding()
 }
}

struct CreatePlaylistView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "ellipsis.circle")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.blue)
 Text("Create Playlists")
 .font(.title2)
 .bold()
 Text("To create a playlist, tap the three‑dot menu next to any song and select 'Add to Playlist.' Organize your favorites with ease!")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 }
 .padding()
 }
}

struct DownloadSongsView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "arrow.down.circle")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.purple)
 Text("Download Songs")
 .font(.title2)
 .bold()
 Text("Need music offline? Tap the three‑dot menu on a song and choose 'Download' to save it for later listening.")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 }
 .padding()
 }
}

struct AlbumDetailsView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "rectangle.stack")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.blue)
 Text("View Album Details")
 .font(.title2)
 .bold()
 Text("Tap the 'Show Album' button (displayed as a stack icon) next to a song to view album details including cover art and track list.")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 }
 .padding()
 }
}

struct DiscoverMusicView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "sparkles")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.blue)
 Text("Discover New Music")
 .font(.title2)
 .bold()
 Text("Explore the New tab to find the latest releases and trending tracks curated just for you!")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 }
 .padding()
 }
}

struct ConnectOthersView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "person.2.fill")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.pink)
 Text("Connect with Others")
 .font(.title2)
 .bold()
 Text("Use the Social tab to view profiles, share music, and join a community of fellow music lovers.")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 }
 .padding()
 }
}

struct CustomizeProfileView: View {
 var body: some View {
 VStack(spacing: 20) {
 Image(systemName: "person.crop.circle.fill.badge.checkmark")
 .resizable()
 .scaledToFit()
 .frame(height: 100)
 .foregroundColor(.green)
 Text("Customize Your Profile")
 .font(.title2)
 .bold()
 Text("Access your profile by tapping the profile button in the top‑right corner. Update your avatar, bio, and settings to make your account uniquely yours.")
 .multilineTextAlignment(.center)
 .padding(.horizontal)
 }
 .padding()
 }
}

