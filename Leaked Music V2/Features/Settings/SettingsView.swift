import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionStore
    
    // Local color states for custom picking
    @State private var customPrimary: Color = .blue
    @State private var customSecondary: Color = .white
    
    var body: some View {
        NavigationView {
            Form {
                
                // MARK: - Preset Themes
                Section(header: Text("Preset Themes")) {
                    ForEach(ThemeManager.Preset.allCases) { preset in
                        Button(action: {
                            let newTheme = preset.theme
                            
                            // Convert SwiftUI → hex
                            let (pHex, sHex) = convertToHexPair(newTheme)
                            
                            // 1) Instantly apply theme locally
                            themeManager.currentTheme = newTheme
                            
                            // 2) Save to Firestore
                            session.updateFirestoreTheme(primaryHex: pHex, secondaryHex: sHex)
                            
                            // 3) Update local color pickers
                            customPrimary = newTheme.primaryColor
                            customSecondary = newTheme.secondaryColor
                        }) {
                            HStack {
                                Text(preset.displayName)
                                Spacer()
                                // Small preview rectangle with the preset’s background gradient
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(preset.theme.backgroundGradient)
                                    .frame(width: 50, height: 20)
                            }
                        }
                    }
                }
                
                // MARK: - Custom Colors
                Section(header: Text("Custom Colors")) {
                    ColorPicker("Primary Color", selection: $customPrimary)
                        .onChange(of: customPrimary) { _ in
                            applyCustomTheme()
                        }
                    
                    ColorPicker("Secondary Color", selection: $customSecondary)
                        .onChange(of: customSecondary) { _ in
                            applyCustomTheme()
                        }
                }
                
                // MARK: - Restore Defaults
                Section {
                    Button("Restore Default Appearance") {
                        restoreDefaultAppearance()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("App Settings")
        }
    }
    
    // Whenever user changes the color pickers
    private func applyCustomTheme() {
        // Build gradient from chosen colors
        let gradient = LinearGradient(
            gradient: Gradient(colors: [customPrimary, customSecondary]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        let newTheme = Theme(
            primaryColor: customPrimary,
            secondaryColor: customSecondary,
            backgroundGradient: gradient
        )
        
        // Convert colors to hex
        let (pHex, sHex) = convertToHexPair(newTheme)
        
        // 1) Update local UI
        themeManager.currentTheme = newTheme
        
        // 2) Persist in Firestore
        session.updateFirestoreTheme(primaryHex: pHex, secondaryHex: sHex)
    }
    
    private func restoreDefaultAppearance() {
        // Decide your default colors
        let defaultPrimary   = Color.pink
        let defaultSecondary = Color.blue
        
        customPrimary   = defaultPrimary
        customSecondary = defaultSecondary
        
        let gradient = LinearGradient(
            gradient: Gradient(colors: [defaultPrimary, defaultSecondary]),
            startPoint: .top,
            endPoint: .bottom
        )
        
        let defaultTheme = Theme(
            primaryColor: defaultPrimary,
            secondaryColor: defaultSecondary,
            backgroundGradient: gradient
        )
        
        // Convert to hex
        let (pHex, sHex) = convertToHexPair(defaultTheme)
        
        // Update UI
        themeManager.currentTheme = defaultTheme
        
        // Push to Firestore
        session.updateFirestoreTheme(primaryHex: pHex, secondaryHex: sHex)
    }
    
    /// Converts a SwiftUI Theme → (#RRGGBB, #RRGGBB)
    private func convertToHexPair(_ theme: Theme) -> (String, String) {
        let uiPrimary   = UIColor(theme.primaryColor)
        let uiSecondary = UIColor(theme.secondaryColor)
        
        let pHex = uiPrimary.toHex() ?? "#000000"
        let sHex = uiSecondary.toHex() ?? "#000000"
        
        return (pHex, sHex)
    }
}
extension UIColor {
    /// Convert a UIColor to a hex string like "#FF0000"
    func toHex() -> String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        // Pull out the RGBA components
        guard getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil
        }
        
        let rgb: Int = (Int)(r * 255) << 16
                     | (Int)(g * 255) << 8
                     | (Int)(b * 255)
        
        // Format into a hex string
        return String(format: "#%06X", rgb)
    }
}
