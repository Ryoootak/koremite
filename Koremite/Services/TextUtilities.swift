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

    static func matchesFuzzy(_ text: String, query: String) -> Bool {
        let normalizedText = normalizeForSearch(text)
        let normalizedQuery = normalizeForSearch(query)
        guard !normalizedQuery.isEmpty else { return true }
        if normalizedText.contains(normalizedQuery) { return true }

        var searchIndex = normalizedText.startIndex
        for character in normalizedQuery {
            guard let found = normalizedText[searchIndex...].firstIndex(of: character) else {
                return false
            }
            searchIndex = normalizedText.index(after: found)
        }
        return true
    }

    private static func normalizeForSearch(_ value: String) -> String {
        value
            .folding(options: [.caseInsensitive, .widthInsensitive, .diacriticInsensitive], locale: .current)
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
