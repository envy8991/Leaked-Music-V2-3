import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                // Page 1: Welcome
                VStack(spacing: 20) {
                    Image(systemName: "music.note.list")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.purple)
                    Text("Welcome to Leaked Music")
                        .font(.largeTitle)
                        .bold()
                    Text("Discover, listen, and share music like never before!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .tag(0)
                
                // Page 2: Premium Features - NEW PAGE
                VStack(spacing: 20) {
                    Image(systemName: "crown.fill") // Crown icon for premium
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.yellow) // Gold color for premium
                    Text("Unlock Premium Features")
                        .font(.largeTitle)
                        .bold()
                    Text("Subscribe to Premium and unlock exclusive capabilities, including uploading your own music to your Personal Library!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("Support the app and grow your music collection.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                }
                .padding()
                .tag(1)
                
                // Page 3: Creating Playlists
                VStack(spacing: 20) {
                    Image(systemName: "ellipsis.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.blue)
                    Text("Create Playlists")
                        .font(.largeTitle)
                        .bold()
                    Text("To create a playlist, tap the three‑dot menu next to any song and select 'Add to Playlist.' Organize your favorites with ease!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .tag(2)
                
                // Page 4: Downloading Songs
                VStack(spacing: 20) {
                    Image(systemName: "arrow.down.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.purple)
                    Text("Download Songs")
                        .font(.largeTitle)
                        .bold()
                    Text("Need music offline? Tap the three‑dot menu on a song and choose 'Download' to save it for later listening.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .tag(3)
                
                // Page 5: View Album Details
                VStack(spacing: 20) {
                    Image(systemName: "rectangle.stack")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.blue)
                    Text("View Album Details")
                        .font(.largeTitle)
                        .bold()
                    Text("Tap the 'Show Album' button (displayed as a stack icon) next to a song to view album details including cover art and track list.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .tag(4)
                
                // Page 6: Discover New Music
                VStack(spacing: 20) {
                    Image(systemName: "sparkles")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.blue)
                    Text("Discover New Music")
                        .font(.largeTitle)
                        .bold()
                    Text("Explore the New tab to find the latest releases and trending tracks curated just for you!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .tag(5)
                
                // Page 7: Social Features
                VStack(spacing: 20) {
                    Image(systemName: "person.2.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.pink)
                    Text("Connect with Others")
                        .font(.largeTitle)
                        .bold()
                    Text("Use the Social tab to view profiles, share music, and join a community of fellow music lovers.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .tag(6)
                
                // Page 8: Customize Your Profile
                VStack(spacing: 20) {
                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.green)
                    Text("Customize Your Profile")
                        .font(.largeTitle)
                        .bold()
                    Text("Access your profile by tapping the profile button in the top‑right corner. Update your avatar, bio, and settings to make your account uniquely yours.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .tag(7)
                
                // Page 9: Join Our Discord
                VStack(spacing: 20) {
                    Image(systemName: "message.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.indigo)
                    Text("Join Our Discord")
                        .font(.largeTitle)
                        .bold()
                    Text("Get support, make donations, request uploads for specific artists, songs, or albums, and chat or collaborate with fellow music lovers!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Link("Join Discord", destination: URL(string: "https://discord.gg/9GwN9yEP")!)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.indigo)
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                .padding()
                .tag(8)
                
                // Final Page: Get Started
                VStack(spacing: 20) {
                    Image(systemName: "hand.point.right.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .foregroundColor(.orange)
                    Text("Ready to Explore?")
                        .font(.largeTitle)
                        .bold()
                    Text("Tap below to start using Leaked Music!")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button(action: {
                        isPresented = false
                        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                    }) {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .tag(9)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            HStack {
                Button(action: {
                    if currentPage > 0 {
                        currentPage -= 1
                    }
                }) {
                    Text("Previous")
                        .padding()
                }
                .disabled(currentPage == 0)

                Spacer()

                Button(action: {
                    if currentPage < 9 {
                        currentPage += 1
                    }
                }) {
                    Text("Next")
                        .padding()
                }
                .disabled(currentPage == 9)
            }
            .padding()
        }
    }
}
