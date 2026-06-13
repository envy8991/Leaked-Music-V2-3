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
}


struct LibraryView: View {
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showPersonalUploadView = false

    var body: some View {
        NavigationView {
            ZStack {
                // Use the current theme's background.
                themeManager.currentTheme.backgroundGradient
                    .ignoresSafeArea()
                
                List {
                    // Personal Upload Section (for admins/paid users)
                    if session.currentUser?.isAdmin == true || session.currentUser?.isPaid == true {
                        Section {
                            Button("Upload to Personal Library") {
                                showPersonalUploadView = true
                            }
                            .foregroundColor(themeManager.currentTheme.primaryColor)
                        }
                    }
                    
                    // Library Categories Section
                    Section(header: Text("Library")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.primaryColor)) {
                        ForEach(LibraryCategory.allCases) { category in
                            NavigationLink(destination: destinationView(for: category)) {
                                Text(category.rawValue)
                                    .font(.body)
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                            }
                        }
                    }
                    
                    // Recently Added Albums Section
                    Section(header: Text("Recently Added Albums")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.primaryColor)) {
                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                ProgressView("Loading...")
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                Spacer()
                            }
                        } else if viewModel.recentlyAddedAlbums.isEmpty {
                            Text("No recent albums found.")
                                .foregroundColor(themeManager.currentTheme.primaryColor.opacity(0.8))
                        } else {
                            ForEach(viewModel.recentlyAddedAlbums) { album in
                                NavigationLink(destination: LibraryAlbumDetailView(album: album)) {
                                    AlbumRow(album: album)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(themeManager.currentTheme.primaryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.secondaryColor.opacity(0.8))
                        .cornerRadius(10)
                    }
                }
            }
            .onAppear {
                viewModel.setupListener()
            }
            .onDisappear {
                viewModel.removeListener()
            }
            .alert(item: $viewModel.localError) { error in
                Alert(title: Text("Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showPersonalUploadView) {
                PersonalUploadView()
            }
        }
    }
    
    @ViewBuilder
    private func destinationView(for category: LibraryCategory) -> some View {
        switch category {
        case .playlists:
            LibraryPlaylistsView()
        case .artists:
            LibraryArtistsView()
        case .albums:
            LibraryAlbumsView()
        case .songs:
            LibrarySongsView()
        case .downloads:
            LibraryDownloadsView()
        }
    }
}
