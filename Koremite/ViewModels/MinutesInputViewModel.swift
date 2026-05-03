import Foundation

@MainActor
final class MinutesInputViewModel: ObservableObject {
    @Published var transcript = ""
    @Published var speakersText = "自分, 相手"
    @Published var category: MeetingCategory = .housing
    @Published var selectedFolderID: String?
    @Published var selectedFocusPoints: Set<FocusPoint> = [.decisions, .todos, .schedule, .concerns]
    @Published var isGenerating = false
    @Published var result: MinutesResult?
    @Published var errorMessage: String?

    let maxInputCharacters = 30_000
    private let aiClient: AIClient

    init(aiClient: AIClient = MockAIClient()) {
        self.aiClient = aiClient
    }

    var characterCount: Int {
        transcript.count
    }

    var canGenerate: Bool {
        !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && characterCount <= maxInputCharacters
            && !isGenerating
    }

    var costHint: String {
        switch TextUtilities.processingMode(for: characterCount) {
        case .short:
            return "短めの文字起こしです。まとめて整理します。"
        case .normal:
            return "内容量に合わせて、共有版と議事録をまとめて作成します。"
        case .longChunked:
            return "長文のため、段階的に整理します。"
        }
    }

    var isOverLimit: Bool {
        characterCount > maxInputCharacters
    }

    func toggle(_ focusPoint: FocusPoint) {
        if selectedFocusPoints.contains(focusPoint) {
            selectedFocusPoints.remove(focusPoint)
        } else {
            selectedFocusPoints.insert(focusPoint)
        }
    }

    func updateCategoryFromFolderName(_ folderName: String?) {
        let name = folderName ?? ""
        if name.contains("住宅") || name.contains("家") || name.contains("ローン") {
            category = .housing
        } else if name.contains("仕事") || name.contains("商談") || name.contains("会議") {
            category = .work
        } else if name.contains("家庭") || name.contains("家族") {
            category = .family
        } else {
            category = .other
        }
    }

    func generate(reusing archiveStore: ArchiveStore? = nil) async {
        let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = AIClientError.emptyInput.localizedDescription
            return
        }
        guard trimmed.count <= maxInputCharacters else {
            errorMessage = AIClientError.tooLong(limit: maxInputCharacters).localizedDescription
            return
        }

        isGenerating = true
        errorMessage = nil

        let request = GenerateMinutesRequest(
            transcript: trimmed,
            category: category,
            speakers: speakersText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) },
            focusPoints: Array(selectedFocusPoints),
            clientRequestId: UUID().uuidString,
            sourceHash: TextUtilities.sourceHash(for: trimmed)
        )

        if let cachedResult = archiveStore?.result(sourceHash: request.sourceHash) {
            result = cachedResult
            isGenerating = false
            return
        }

        do {
            var generatedResult = try await aiClient.generateMinutes(request: request)
            generatedResult.sourceHash = request.sourceHash
            generatedResult.createdAt = Date()
            result = generatedResult
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "議事録を生成できませんでした。"
        }

        isGenerating = false
    }
}
