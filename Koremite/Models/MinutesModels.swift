import Foundation

enum MeetingCategory: String, CaseIterable, Codable, Identifiable {
    case housing = "住宅"
    case work = "仕事"
    case family = "家庭"
    case other = "その他"

    var id: String { rawValue }
}

enum FocusPoint: String, CaseIterable, Codable, Identifiable {
    case decisions = "話の流れ"
    case todos = "話題ごとのポイント"
    case money = "金額"
    case schedule = "スケジュール"
    case concerns = "懸念点"
    case emotion = "感情"

    var id: String { rawValue }
}

enum ProcessingMode: String, Codable {
    case short
    case normal
    case longChunked = "long_chunked"
}

struct TodoItem: Codable, Hashable, Identifiable {
    var id = UUID()
    let owner: String?
    let task: String
    let due: String?

    enum CodingKeys: String, CodingKey {
        case owner, task, due
    }
}

struct ShareSummary: Codable, Hashable {
    let text: String
    let decisions: [String]
    let todos: [TodoItem]
    let confirmationPoints: [String]
}

struct DetailedMinutes: Codable, Hashable {
    let overview: String
    let topics: [String]
    let decisions: [String]
    let openIssues: [String]
    let todos: [TodoItem]
    let importantRemarks: [String]
    let nextMeetingNotes: [String]
}

struct FullLogEntry: Codable, Hashable, Identifiable {
    var id = UUID()
    var speaker: String
    var text: String

    enum CodingKeys: String, CodingKey {
        case speaker, text
    }
}

struct CostInfo: Codable, Hashable {
    let inputLength: Int
    let processingMode: ProcessingMode
    let cacheHit: Bool
}

struct MinutesResult: Codable, Hashable, Identifiable {
    var id = UUID()
    let title: String
    let shareSummary: ShareSummary
    let detailedMinutes: DetailedMinutes
    var fullLog: [FullLogEntry]
    let category: MeetingCategory
    let confidenceWarnings: [String]
    let costInfo: CostInfo
    var createdAt = Date()
    var sourceHash: String?

    enum CodingKeys: String, CodingKey {
        case title, shareSummary, detailedMinutes, fullLog, category, confidenceWarnings, costInfo
    }
}

struct GenerateMinutesRequest: Codable {
    let transcript: String
    let category: MeetingCategory
    let speakers: [String]
    let focusPoints: [FocusPoint]
    let clientRequestId: String
    let sourceHash: String
}

extension MinutesResult {
    var copyText: String {
        var lines: [String] = [
            title,
            "",
            "話の流れ",
            detailedMinutes.overview
        ]

        append("話題ごとのポイント", detailedMinutes.topics, to: &lines)
        append("AIが気になったこと", detailedMinutes.openIssues, to: &lines)
        return lines.joined(separator: "\n")
    }

    private func append(_ heading: String, _ values: [String], to lines: inout [String]) {
        guard !values.isEmpty else { return }
        lines.append("")
        lines.append(heading)
        lines.append(contentsOf: values.map { "- \($0)" })
    }
}
