import Foundation
import os.log

struct Logger {
    static func log(_ message: String, error: Error? = nil) {
        let timestamp = Date()
        if let error = error {
            os_log("[%@] ERROR: %@ - %@", "\(timestamp)", message, error.localizedDescription)
            print("[\(timestamp)] ERROR: \(message) - \(error.localizedDescription)")
        } else {
            os_log("[%@] %@", "\(timestamp)", message)
            print("[\(timestamp)] \(message)")
        }
    }
}
