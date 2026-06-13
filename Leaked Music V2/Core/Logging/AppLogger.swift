import Foundation
import OSLog

enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "LeakedMusicV2"
    private static let logger = OSLog.Logger(subsystem: subsystem, category: "App")
    private static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func log(_ message: String, error: Error? = nil) {
        let timestamp = formatter.string(from: Date())
        if let error {
            logger.error("[\(timestamp, privacy: .public)] \(message, privacy: .public) - \(error.localizedDescription, privacy: .public)")
        } else {
            logger.info("[\(timestamp, privacy: .public)] \(message, privacy: .public)")
        }
    }
}
