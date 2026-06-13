import SwiftUI
import FirebaseFirestore

struct NewView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var viewModel: NewViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Use the current theme's background gradient behind everything
                themeManager.currentTheme.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        if viewModel.isLoading {
                            ProgressView("Loading...")
                                .font(.headline)
                                .padding()
                                .transition(.opacity)
                        } else {
                            // Artists Section
                            if !viewModel.alphabeticalArtists.isEmpty {
                                Text("Artists")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                    .padding(.horizontal, 20)
                                ArtistListView(artists: viewModel.alphabeticalArtists)
                                NavigationLink(destination: AllArtistsView(viewModel: viewModel)) {
                                    HStack {
                                        Spacer()
                                        Text("See All Artists")
                                            .foregroundColor(themeManager.currentTheme.primaryColor)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(themeManager.currentTheme.secondaryColor.opacity(0.8))
                                    .cornerRadius(10)
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // New Albums Section
                            if !viewModel.newAlbums.isEmpty {
                                Text("New Albums")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                    .padding(.horizontal, 20)
                                AlbumListView(albums: viewModel.newAlbums)
                            }
                            // New Songs Section
                            if !viewModel.newSongs.isEmpty {
                                Text("New Songs")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                    .padding(.horizontal, 20)
                                SongListView(songs: viewModel.newSongs)
                            }
                            // Featured Songs Section
                            if !viewModel.featuredSongs.isEmpty {
                                Text("Featured Songs")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                    .padding(.horizontal, 20)
                                SongListView(songs: viewModel.featuredSongs)
                            }
                            // Top Songs Section
                            if !viewModel.topSongs.isEmpty {
                                Text("Top Songs")
                                    .font(.title2)
                                    .bold()
                                    .foregroundColor(themeManager.currentTheme.primaryColor)
                                    .padding(.horizontal, 20)
                                SongListView(songs: viewModel.topSongs)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                // 2) Hide the default scroll background on iOS 16+
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New")
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
                if viewModel.newAlbums.isEmpty &&
                    viewModel.newSongs.isEmpty &&
                    viewModel.featuredSongs.isEmpty &&
                    viewModel.topSongs.isEmpty &&
                    viewModel.alphabeticalArtists.isEmpty &&
                    viewModel.allArtists.isEmpty {
                    viewModel.setupListeners()
                }
            }
            .onDisappear {
                viewModel.removeListeners()
            }
            .alert(item: $viewModel.localError) { error in
                Alert(title: Text("Error"),
                      message: Text(error.message),
                      dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
