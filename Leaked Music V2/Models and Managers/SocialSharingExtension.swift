//
//  SocialSharingExtension.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/12/25.
//

import SwiftUI

extension View {
    func shareContent(_ items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        root.present(activityVC, animated: true, completion: nil)
    }
}
