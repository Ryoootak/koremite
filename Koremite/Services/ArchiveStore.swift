import Foundation
import SwiftData

@MainActor
final class ArchiveStore: ObservableObject {
    @Published private(set) var items: [MinutesResult] = []
    @Published private(set) var lastErrorMessage: String?

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        refresh()
    }

    func save(_ result: MinutesResult) {
        guard let modelContext else {
            lastErrorMessage = "保存先を準備できていません。"
            return
        }

        if let sourceHash = result.sourceHash, items.contains(where: { $0.sourceHash == sourceHash }) {
            return
        }

        do {
            let record = try ArchivedMinutesRecord(result: result)
            modelContext.insert(record)
            try modelContext.save()
            refresh()
        } catch {
            lastErrorMessage = "議事録を保存できませんでした。"
        }
    }

    func delete(_ result: MinutesResult) {
        guard let modelContext else {
            lastErrorMessage = "保存先を準備できていません。"
            return
        }

        do {
            let resultID = result.id.uuidString
            let sourceHash = result.sourceHash
            let records = try modelContext.fetch(FetchDescriptor<ArchivedMinutesRecord>())
                .filter { record in
                    record.recordID == resultID || (sourceHash != nil && record.sourceHash == sourceHash)
                }
            records.forEach { modelContext.delete($0) }
            try modelContext.save()
            refresh()
        } catch {
            lastErrorMessage = "議事録を削除できませんでした。"
        }
    }

    func search(_ query: String) -> [MinutesResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return items
        }

        return items.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.shareSummary.text.localizedCaseInsensitiveContains(query)
                || $0.detailedMinutes.overview.localizedCaseInsensitiveContains(query)
        }
    }

    func result(sourceHash: String) -> MinutesResult? {
        items.first { $0.sourceHash == sourceHash }
    }

    func refresh() {
        guard let modelContext else { return }

        do {
            var descriptor = FetchDescriptor<ArchivedMinutesRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = 300
            items = try modelContext.fetch(descriptor).compactMap { $0.decodedResult() }
        } catch {
            lastErrorMessage = "保存済み議事録を読み込めませんでした。"
        }
    }
}
