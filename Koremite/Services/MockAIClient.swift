import Foundation

struct MockAIClient: AIClient {
    func generateMinutes(request: GenerateMinutesRequest) async throws -> MinutesResult {
        try await Task.sleep(nanoseconds: 800_000_000)

        let mode: ProcessingMode
        switch request.transcript.count {
        case 0..<2_000:
            mode = .short
        case 2_000..<8_000:
            mode = .normal
        default:
            mode = .longChunked
        }

        let category = request.category
        let firstSpeaker = request.speakers.first?.isEmpty == false ? request.speakers.first! : "話者A"

        return MinutesResult(
            title: "\(category.rawValue)の打ち合わせメモ",
            shareSummary: ShareSummary(
                text: "貼り付けられた内容をもとに、話の全体像を短く整理しました。細かい条件や日付などは、元の記録とあわせて見返すと安心です。",
                decisions: [],
                todos: [],
                confirmationPoints: []
            ),
            detailedMinutes: DetailedMinutes(
                overview: "貼り付けられた文字起こしをもとに、話がどんな順番で進んだかを自然な日本語で整理しました。入力にない内容は足さず、あとから見返しやすい粒度にしています。",
                topics: ["最初に話された内容", "途中で触れられた条件や背景", "最後に確認された内容"],
                decisions: [],
                openIssues: ["金額、日付、固有名詞などは、原文の表現と照らして確認するとよさそうです。"],
                todos: [],
                importantRemarks: [],
                nextMeetingNotes: []
            ),
            fullLog: [
                FullLogEntry(speaker: firstSpeaker, text: request.transcript.prefix(220).description),
                FullLogEntry(speaker: "Koremite", text: "長い原文は、必要な要点に整理して見返せます。")
            ],
            category: category,
            confidenceWarnings: ["これは開発用MockAIClientの生成結果です。"],
            costInfo: CostInfo(inputLength: request.transcript.count, processingMode: mode, cacheHit: false),
            sourceHash: request.sourceHash
        )
    }
}
