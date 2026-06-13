import SwiftUI
import FirebaseFirestore

// MARK: - SocialView

struct SocialView: View {
    enum SocialTab: String, CaseIterable, Identifiable {
        case profiles = "Users"
        var id: String { self.rawValue }
    }
    
    // Although we have a segmented picker defined, it’s hidden since we only use one tab.
    @State private var selectedTab: SocialTab = .profiles
    @StateObject var profileSearchViewModel = ProfileSearchViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                // Picker is hidden (can be enabled later if additional social tabs are added)
                Picker("Social", selection: $selectedTab) {
                    ForEach(SocialTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                .hidden()
                
                // Main content: profile search results
                ProfileSearchTabView(viewModel: profileSearchViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Social")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ProfileView()) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.8))
                        .cornerRadius(10)
                    }
                }
            }
            .appBackground()
            .onAppear {
                profileSearchViewModel.loadAllUsers()
            }
        }
    }
}

// MARK: - ProfileSearchTabView

struct ProfileSearchTabView: View {
    @ObservedObject var viewModel: ProfileSearchViewModel
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            SearchBar(text: $searchText, placeholder: "Search usernames")
                .padding(.horizontal)
            
            ZStack {
                if viewModel.isLoading {
                    ProgressView("Loading User Profiles...")
                } else if viewModel.filteredUsers.isEmpty {
                    Text("No profiles found matching '\(searchText)'")
                        .foregroundColor(.gray)
                } else {
                    List {
                        ForEach(viewModel.filteredUsers) { user in
                            NavigationLink(destination: UserProfileView(user: user)) {
                                HStack {
                                    Text(user.username)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    // Show Online/Offline status
                                    Text(user.isOnline ? "Online" : "Offline")
                                        .font(.subheadline)
                                        .foregroundColor(user.isOnline ? .green : .gray)
                                        .italic()
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .onChange(of: searchText) { newText in
                viewModel.filterUsers(searchText: newText)
            }
        }
    }
}

// MARK: - ProfileSearchViewModel

class ProfileSearchViewModel: ObservableObject {
    @Published var allUsers: [UserProfile] = []
    @Published var filteredUsers: [UserProfile] = []
    @Published var isLoading = false
    @Published var error: AppError? = nil
    
    func loadAllUsers() {
        isLoading = true
        let db = Firestore.firestore()
        db.collection("users").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.error = AppError(message: "Failed to load user profiles: \(error.localizedDescription)")
                    Logger.log("Error loading user profiles", error: error)
                    return
                }
                if let snapshot = snapshot {
                    self.allUsers = snapshot.documents.compactMap { document in
                        var userProfile = try? document.data(as: UserProfile.self)
                        userProfile?.uid = document.documentID
                        return userProfile
                    }
                    // By default, when search text is empty, show only admin accounts.
                    self.filteredUsers = self.allUsers.filter { $0.isAdmin }
                }
            }
        }
    }
    
    func filterUsers(searchText: String) {
        if searchText.isEmpty {
            // Show only admin accounts if there is no search text.
            filteredUsers = allUsers.filter { $0.isAdmin }
        } else {
            let lowercasedSearchText = searchText.lowercased()
            // When a search query is entered, show all matching users.
            filteredUsers = allUsers.filter { user in
                user.username.lowercased().contains(lowercasedSearchText)
            }
        }
    }
}

// MARK: - Reusable SearchBar

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
        .foregroundColor(.secondary)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10.0)
    }
}
