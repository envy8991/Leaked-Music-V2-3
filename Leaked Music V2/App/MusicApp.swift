import SwiftUI
import Firebase

@main
struct MusicApp: App {
    @StateObject var session = SessionStore()
    @StateObject var themeManager = ThemeManager()
    
    init() {
        FirebaseApp.configure()

        // Make NavBar transparent, etc. ...
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = .clear
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
                .environmentObject(themeManager)
                .onAppear {
                    // Now it's safe to reference `session` because
                    // it’s attached to a SwiftUI view hierarchy.
                    session.themeManager = themeManager
                }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    @State private var showOnboarding: Bool = false

    var body: some View {
        Group {
            if session.isLoggedIn {
                // All logged-in users get full access regardless of payment
                MainTabView()
            } else {
                AuthView()
            }
        }
        .environmentObject(session)
        .toast(message: $session.toastMessage)
        .alert(item: $session.appError) { error in
            Alert(title: Text("Error"),
                  message: Text(error.message),
                  dismissButton: .default(Text("OK"), action: { session.appError = nil }))
        }
        .onOpenURL { url in
            Logger.log("Deep link received: \(url)")
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            Logger.log("App became active")
            session.updateOnlineStatus(isOnline: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            Logger.log("App will resign active")
            session.updateOnlineStatus(isOnline: false)
        }
        .onAppear {
            // Check if onboarding has been shown before.
            if !UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                showOnboarding = true
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
}
