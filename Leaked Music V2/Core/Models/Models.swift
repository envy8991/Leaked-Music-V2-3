//
//  Models.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/13/25.
//

// Models.swift
import FirebaseFirestore
import SwiftUI

// New Model for persistent Vote data
struct Vote: Identifiable, Codable {
    @DocumentID var id: String?
    var songId: String
    var userId: String
    var voteValue: Int // e.g. +1 for an upvote; use 0 for no vote
}

// New Model for CommentLike (to allow liking comments)
struct CommentLike: Identifiable, Codable {
    @DocumentID var id: String?
    var commentId: String
    var userId: String
}

// New Model for in‑app Notifications
struct AppNotification: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String  // Recipient’s uid
    var message: String
    var timestamp: Date
    var isRead: Bool = false
}

// Extend CustomTheme to support a secondary color (and potentially more customizations)


// Extend CustomTheme to support a secondary color (and potentially more customizations)
//
//  Models.swift
//  Leaked Music V2
//
//  Created by Quinton Thompson on <some_date>.
//


// MARK: - CustomTheme for storing user's Firestore-based color picks
struct CustomTheme: Codable {
    var primaryColorHex: String
    var secondaryColorHex: String
    
    // Convert hex → SwiftUI Color with a fallback if invalid
    var primaryColor: Color {
        if let uiColor = UIColor(hex: primaryColorHex) {
            return Color(uiColor) // <-- no "forcedLight" call here
        }
        return .blue // fallback if hex is invalid
    }
    
    var secondaryColor: Color {
        if let uiColor = UIColor(hex: secondaryColorHex) {
            return Color(uiColor) // <-- no "forcedLight" call here
        }
        return .white // fallback if hex is invalid
    }
    
    // Provide default hex values for safe fallback
    init(primaryColorHex: String, secondaryColorHex: String = "#FFFFFF") {
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
    }
}

// (You can keep your UIColor(hex:) extension somewhere else, e.g. in a Utilities file.)
extension UIColor {
    /// Convert a hex string like "#FF0000" into a UIColor.
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        guard hexString.count == 6 else { return nil }

        var rgbValue: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgbValue)
        
        let r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgbValue & 0x0000FF)       / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
