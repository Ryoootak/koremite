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
                text: "今日の打ち合わせでは、現状の確認と次に進める事項を整理しました。決まった内容は共有し、未確定の点は次回までに確認します。特にスケジュールと費用に関わる部分は、認識違いが出ないよう追加確認します。",
                decisions: ["共有用の要点と詳細な記録を分けて残す", "確認が必要な点は要確認として扱う"],
                todos: [
                    TodoItem(owner: firstSpeaker, task: "次回までに未確定事項を確認する", due: nil),
                    TodoItem(owner: nil, task: "関係者に共有版を送る", due: nil)
                ],
                confirmationPoints: ["金額や日付は原文に明記がある場合のみ確定扱いにする"]
            ),
            detailedMinutes: DetailedMinutes(
                overview: "貼り付けられた文字起こしをもとに、共有しやすい要点と後から確認できる記録へ整理しました。MVPでは音声を扱わず、テキストだけを処理対象にします。",
                topics: ["現状確認", "決定事項の整理", "TODOの確認", "次回までの確認事項"],
                decisions: ["文字起こし全文をそのまま共有せず、短い共有版と詳細記録を分ける"],
                openIssues: ["不明確な発言者や日付は要確認"],
                todos: [
                    TodoItem(owner: firstSpeaker, task: "重要な確認事項を洗い出す", due: "次回まで"),
                    TodoItem(owner: nil, task: "議事録を保存し、必要に応じて共有する", due: nil)
                ],
                importantRemarks: ["入力にない事実は追加しない", "決定事項と推測を混ぜない"],
                nextMeetingNotes: ["費用、日程、担当者が曖昧な箇所を確認する"]
            ),
            fullLog: [
                FullLogEntry(speaker: firstSpeaker, text: request.transcript.prefix(220).description),
                FullLogEntry(speaker: "Koremite", text: "長い原文はアーカイブと全量ログで確認できる前提です。")
            ],
            category: category,
            confidenceWarnings: ["これは開発用MockAIClientの生成結果です。"],
            costInfo: CostInfo(inputLength: request.transcript.count, processingMode: mode, cacheHit: false),
            sourceHash: request.sourceHash
        )
    }
}
