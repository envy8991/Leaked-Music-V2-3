import SwiftUI
import UIKit

// MARK: - A simple "Theme" model for the local UI
struct Theme {
    var primaryColor: Color
    var secondaryColor: Color
    var backgroundGradient: LinearGradient
}

// MARK: - ThemeManager
class ThemeManager: ObservableObject {
    
    /// The currently active theme for your SwiftUI UI.
    @Published var currentTheme: Theme
    
    /// Initializes the manager with some default local theme.
    /// If the user is logged in, SessionStore will override this
    /// with Firestore-based colors by calling `setThemeFromFirestore(...)`.
    init() {
        // Example default: Blue → White gradient
        let defaultPrimary = Color(red: 0.0, green: 0.0, blue: 1.0)
        let defaultSecondary = Color.white
        
        let gradient = LinearGradient(
            gradient: Gradient(colors: [defaultPrimary, defaultSecondary]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        self.currentTheme = Theme(
            primaryColor: defaultPrimary,
            secondaryColor: defaultSecondary,
            backgroundGradient: gradient
        )
    }
    
    // MARK: - Apply a Firestore-based custom theme at runtime
    /// Call this whenever SessionStore fetches the user doc from Firestore.
    func setThemeFromFirestore(_ customTheme: CustomTheme) {
        // Force Light mode so dynamic colors won't go black
        let uiPrimary   = UIColor(customTheme.primaryColor)
        let uiSecondary = UIColor(customTheme.secondaryColor)
        
        // Build a linear gradient
        let gradient = LinearGradient(
            gradient: Gradient(colors: [Color(uiPrimary), Color(uiSecondary)]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Update the published theme (will refresh the UI)
        self.currentTheme = Theme(
            primaryColor: Color(uiPrimary),
            secondaryColor: Color(uiSecondary),
            backgroundGradient: gradient
        )
    }
    
    // MARK: - Optional: If you want "preset" themes purely in the local UI
    enum Preset: String, CaseIterable, Identifiable {
        case blueWhite, redBlack, purpleOrange, vibrant, sunset, forest, ocean, fire
        
        var id: String { rawValue }
        
        /// Returns a local SwiftUI `Theme` for each preset
        var theme: Theme {
            switch self {
            case .blueWhite:
                let primary   = Color(red: 0, green: 0, blue: 1)
                let secondary = Color.white
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
                
            case .redBlack:
                let primary   = Color(red: 1, green: 0, blue: 0)
                let secondary = Color.black
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
                
            case .purpleOrange:
                let primary   = Color(red: 0.5, green: 0.0, blue: 0.5)
                let secondary = Color(red: 1.0, green: 0.65, blue: 0.0)
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
                
            case .vibrant:
                let primary   = Color(red: 1.0, green: 0.0, blue: 0.5)
                let mid       = Color(red: 0.5, green: 0.0, blue: 0.5)
                let secondary = Color(red: 0.0, green: 0.0, blue: 1.0)
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, mid, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
                
            case .sunset:
                let primary   = Color(red: 1.0, green: 0.5, blue: 0.0)
                let middle    = Color(red: 1.0, green: 0.0, blue: 0.0)
                let secondary = Color(red: 1.0, green: 0.0, blue: 0.5)
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, middle, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
                
            case .forest:
                let primary   = Color(red: 0.0, green: 0.5, blue: 0.0)
                let secondary = Color(red: 0.0, green: 0.75, blue: 0.75)
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
                
            case .ocean:
                let primary   = Color(red: 0.0, green: 0.0, blue: 1.0)
                let secondary = Color(red: 0.0, green: 1.0, blue: 1.0)
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
                
            case .fire:
                let primary   = Color(red: 1.0, green: 0.0, blue: 0.0)
                let middle    = Color(red: 1.0, green: 0.5, blue: 0.0)
                let secondary = Color(red: 1.0, green: 1.0, blue: 0.0)
                let grad = LinearGradient(
                    gradient: Gradient(colors: [primary, middle, secondary]),
                    startPoint: .top, endPoint: .bottom
                )
                return Theme(primaryColor: primary, secondaryColor: secondary, backgroundGradient: grad)
            }
        }
    }
}

// MARK: - UIColor Extension with forced Light Mode
