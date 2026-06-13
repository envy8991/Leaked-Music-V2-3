//
//  NetworkMonitor.swift
//  Leaked Music V2
//
//  Created by Quinton  Thompson  on 2/12/25.
//


//
//  NetworkMonitor.swift
//

import Network
import Combine
import SwiftUI
import Foundation

class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                self.logMessage("Network: \(self.isConnected ? "Connected" : "Disconnected")")
            }
        }
        monitor.start(queue: queue)
    }
    
    private func logMessage(_ message: String) {
        Logger.log(message)
    }
}
