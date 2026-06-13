import SwiftUI

struct AdminView: View {
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Upload Content", destination: UploadContentView())
                NavigationLink("Manage Users", destination: ManageUsersView())
                NavigationLink("Manage Content", destination: ManageContentView())
                NavigationLink("Manage Artists", destination: ManageArtistsView())
                NavigationLink("Analytics", destination: AnalyticsView())
            }
            .navigationTitle("Admin Panel")
            .appBackground() // Your custom background modifier
        }
    }
}
