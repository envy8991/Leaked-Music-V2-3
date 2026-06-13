import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MusicKit

enum LibraryCategory: String, CaseIterable, Identifiable {
    case playlists = "Playlists"
    case artists   = "Artists"
    case albums    = "Albums"
    case songs     = "Songs"
    case downloads = "Downloaded"

    var id: String { self.rawValue }

    var systemImage: String {
        switch self {
        case .playlists: return "music.note.list"
        case .artists: return "music.mic"
        case .albums: return "square.stack"
        case .songs: return "music.note"
        case .downloads: return "arrow.down.circle"
        }
    }

    var description: String {
        switch self {
        case .playlists: return "Curated mixes and saved queues"
        case .artists: return "Browse your saved artists"
        case .albums: return "Albums added to your library"
        case .songs: return "Personal uploads and saved tracks"
        case .downloads: return "Available offline"
        }
    }
}


struct LibraryView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showPersonalUploadView = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    quickActions
                    categoryGrid
                    recentlyAddedAlbums
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(themeManager.currentTheme.backgroundGradient.ignoresSafeArea())
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.crop.circle")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                    }
                }
            }
            .onAppear { viewModel.setupListener() }
            .onDisappear { viewModel.removeListener() }
            .alert(item: $viewModel.localError) { error in
                Alert(title: Text("Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showPersonalUploadView) { PersonalUploadView() }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your music, organized")
                .font(.largeTitle.bold())
                .foregroundColor(themeManager.currentTheme.textColor)
            Text("Jump into saved songs, personal uploads, downloads, playlists, artists, and albums from one cleaner hub.")
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textColor.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }

    @ViewBuilder
    private var quickActions: some View {
        if session.currentUser?.isAdmin == true || session.currentUser?.isPaid == true {
            Button(action: { showPersonalUploadView = true }) {
                Label("Upload to Personal Library", systemImage: "square.and.arrow.up")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(LibraryCategory.allCases) { category in
                NavigationLink(destination: destinationView(for: category)) {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(systemName: category.systemImage)
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                        Text(category.rawValue)
                            .font(.headline)
                            .foregroundColor(themeManager.currentTheme.textColor)
                        Text(category.description)
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textColor.opacity(0.65))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                    .padding()
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                }
            }
        }
    }

    private var recentlyAddedAlbums: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Added Albums")
                .font(.title3.bold())
                .foregroundColor(themeManager.currentTheme.textColor)

            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.recentlyAddedAlbums.isEmpty {
                Text("No recent albums found.")
                    .foregroundColor(themeManager.currentTheme.textColor.opacity(0.72))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.recentlyAddedAlbums.prefix(6)) { album in
                        NavigationLink(destination: LibraryAlbumDetailView(album: album)) {
                            AlbumRow(album: album)
                                .padding(10)
                                .background(cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if themeManager.currentTheme.isGlassStyle {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(themeManager.currentTheme.surfaceColor)
        } else {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.82))
        }
    }
    
    @ViewBuilder
    private func destinationView(for category: LibraryCategory) -> some View {
        switch category {
        case .playlists: LibraryPlaylistsView()
        case .artists: LibraryArtistsView()
        case .albums: LibraryAlbumsView()
        case .songs: LibrarySongsView()
        case .downloads: LibraryDownloadsView()
        }
    }
}
