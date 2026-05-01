import CryptoKit
import Foundation

enum TextUtilities {
    static func sourceHash(for text: String) -> String {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let digest = SHA256.hash(data: Data(normalized.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func processingMode(for count: Int) -> ProcessingMode {
        switch count {
        case 0..<2_000:
            return .short
        case 2_000..<8_000:
            return .normal
        default:
            return .longChunked
        }
    }
}
