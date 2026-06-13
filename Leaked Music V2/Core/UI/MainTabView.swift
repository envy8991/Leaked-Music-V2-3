import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    @ObservedObject var playerManager = AudioPlayerManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    
    // Create single, persistent view models for "New" and "Library"
    @StateObject private var newVM = NewViewModel()
    @StateObject private var libraryVM = LibraryViewModel()
    
    @State private var selectedTab: Tab = .new

    enum Tab: String {
        case new, library, search, social
    }

    // Dimensions for mini-player & tab bar
    private let miniPlayerHeight: CGFloat = 70
    private let tabBarHeight: CGFloat = 60
    private let tabBarBottomPadding: CGFloat = 20

    /// Computed property to decide how much space to reserve at the bottom.
    private var bottomPadding: CGFloat {
        // If there is a current song, reserve space for both the mini-player & tab bar.
        // If not, reserve space only for the tab bar.
        if playerManager.currentSong != nil {
            return miniPlayerHeight + tabBarHeight + tabBarBottomPadding
        } else {
            return tabBarHeight + tabBarBottomPadding
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area for each tab
            Group {
                switch selectedTab {
                case .new:
                    NewView(viewModel: newVM)
                case .library:
                    LibraryView(viewModel: libraryVM)
                case .search:
                    SearchView()
                case .social:
                    SocialView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .appBackground()
            // Use the computed property so we only add extra padding when a song is playing
            .padding(.bottom, bottomPadding)

            // Mini Player + Custom Tab Bar
            VStack(spacing: 0) {
                // Show the mini-player if a song is playing
                if playerManager.currentSong != nil {
                    MiniPlayerView(playerManager: playerManager)
                        .frame(height: miniPlayerHeight)
                        .background(Color.clear)
                        .transition(.move(edge: .bottom))
                }
                
                // Custom tab bar
                HStack {
                    TabBarButton(tab: .new,
                                 selectedTab: $selectedTab,
                                 label: "New",
                                 systemImage: "sparkles")
                    
                    Spacer()
                    
                    TabBarButton(tab: .library,
                                 selectedTab: $selectedTab,
                                 label: "Library",
                                 systemImage: "folder.fill")
                    
                    Spacer()
                    
                    TabBarButton(tab: .search,
                                 selectedTab: $selectedTab,
                                 label: "Search",
                                 systemImage: "magnifyingglass")
                    
                    Spacer()
                    
                    TabBarButton(tab: .social,
                                 selectedTab: $selectedTab,
                                 label: "Social",
                                 systemImage: "person.2.fill")
                }
                .padding(.horizontal, 20)
                .frame(height: tabBarHeight)
                .background(tabBarBackground)
                .clipShape(RoundedRectangle(cornerRadius: themeManager.currentTheme.isGlassStyle ? 26 : 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.2), radius: 6, y: -2)
            }
            .padding(.bottom, tabBarBottomPadding)
            .transition(.opacity)
        }
        // Allow our custom layout to extend to the screen bottom
        .edgesIgnoringSafeArea(.bottom)
    }

    @ViewBuilder
    private var tabBarBackground: some View {
        if themeManager.currentTheme.isGlassStyle {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(themeManager.currentTheme.surfaceColor)
        } else {
            Color(UIColor.systemBackground)
        }
    }
}

/// A reusable button used in MainTabView’s custom tab bar.
struct TabBarButton: View {
    let tab: MainTabView.Tab
    @Binding var selectedTab: MainTabView.Tab
    let label: String
    let systemImage: String

    var body: some View {
        Button(action: {
            withAnimation(.spring()) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tab ? Color.accentColor : .gray)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
