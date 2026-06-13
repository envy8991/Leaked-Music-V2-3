//
//  AppBackground.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/12/25.
//



import SwiftUI

struct AppBackground: ViewModifier {
    // Pull in the theme from the environment
    @EnvironmentObject var themeManager: ThemeManager
    
    func body(content: Content) -> some View {
        ZStack {
            // Use the theme’s gradient
            themeManager.currentTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            // Then place content on top
            content
        }
    }
}

extension View {
    func appBackground() -> some View {
        self.modifier(AppBackground())
    }
}
