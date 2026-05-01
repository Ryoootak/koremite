import Foundation
import SwiftData

@Model
final class ArchivedMinutesRecord {
    @Attribute(.unique) var recordID: String
    var sourceHash: String?
    var title: String
    var categoryRawValue: String
    var shareText: String
    var overview: String
    var createdAt: Date
    var resultData: Data

    init(result: MinutesResult) throws {
        self.recordID = result.id.uuidString
        self.sourceHash = result.sourceHash
        self.title = result.title
        self.categoryRawValue = result.category.rawValue
        self.shareText = result.shareSummary.text
        self.overview = result.detailedMinutes.overview
        self.createdAt = result.createdAt
        self.resultData = try JSONEncoder().encode(result)
    }

    func decodedResult() -> MinutesResult? {
        guard var result = try? JSONDecoder().decode(MinutesResult.self, from: resultData) else {
            return nil
        }

        result.createdAt = createdAt
        result.sourceHash = sourceHash
        return result
    }
}
