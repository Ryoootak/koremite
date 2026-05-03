import Foundation
import SwiftData

@MainActor
final class ArchiveStore: ObservableObject {
    @Published private(set) var items: [MinutesResult] = []
    @Published private(set) var folders: [FolderRecord] = []
    /// Maps result UUID string → folderID for quick lookup in views
    @Published private(set) var folderAssignments: [String: String] = [:]
    @Published private(set) var lastErrorMessage: String?

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        refresh()
    }

    // MARK: - Items

    func save(_ result: MinutesResult, folderID: String? = nil) {
        guard let modelContext else {
            lastErrorMessage = "保存先を準備できていません。"
            return
        }

        // If already saved, update folder assignment only.
        let resultID = result.id.uuidString
        let sourceHash = result.sourceHash
        if let existing = (try? modelContext.fetch(FetchDescriptor<ArchivedMinutesRecord>()))?.first(where: {
            $0.recordID == resultID || (sourceHash != nil && $0.sourceHash == sourceHash)
        }) {
            existing.folderID = folderID
            try? modelContext.save()
            refresh()
            return
        }

        do {
            let record = try ArchivedMinutesRecord(result: result)
            record.folderID = folderID
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

    func setFolder(for result: MinutesResult, folderID: String?) {
        guard let modelContext else { return }

        let resultID = result.id.uuidString
        let sourceHash = result.sourceHash

        do {
            let records = try modelContext.fetch(FetchDescriptor<ArchivedMinutesRecord>())
                .filter { $0.recordID == resultID || (sourceHash != nil && $0.sourceHash == sourceHash) }
            records.forEach { $0.folderID = folderID }
            try modelContext.save()
            refresh()
        } catch {
            lastErrorMessage = "フォルダを更新できませんでした。"
        }
    }

    func isSaved(_ result: MinutesResult) -> Bool {
        let resultID = result.id.uuidString
        if items.contains(where: { $0.id.uuidString == resultID }) { return true }
        if let sourceHash = result.sourceHash, items.contains(where: { $0.sourceHash == sourceHash }) { return true }
        return false
    }

    func search(_ query: String) -> [MinutesResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { result in
            let searchableText = [
                result.title,
                result.category.rawValue,
                result.shareSummary.text,
                result.detailedMinutes.overview,
                result.detailedMinutes.topics.joined(separator: " "),
                result.detailedMinutes.decisions.joined(separator: " "),
                result.detailedMinutes.openIssues.joined(separator: " "),
                result.detailedMinutes.importantRemarks.joined(separator: " "),
                result.detailedMinutes.nextMeetingNotes.joined(separator: " "),
                result.fullLog.map { "\($0.speaker) \($0.text)" }.joined(separator: " ")
            ].joined(separator: " ")
            return TextUtilities.matchesFuzzy(searchableText, query: trimmed)
        }
    }

    func result(sourceHash: String) -> MinutesResult? {
        items.first { $0.sourceHash == sourceHash }
    }

    // MARK: - Folders

    func createFolder(name: String, folderID: String = UUID().uuidString) {
        guard let modelContext else { return }
        let folder = FolderRecord(name: name, folderID: folderID)
        modelContext.insert(folder)
        try? modelContext.save()
        refreshFolders()
    }

    func deleteFolder(_ folder: FolderRecord, removeItems: Bool) {
        guard let modelContext else { return }

        do {
            let allRecords = try modelContext.fetch(FetchDescriptor<ArchivedMinutesRecord>())
            let inFolder = allRecords.filter { $0.folderID == folder.folderID }
            if removeItems {
                inFolder.forEach { modelContext.delete($0) }
            } else {
                inFolder.forEach { $0.folderID = nil }
            }
            modelContext.delete(folder)
            try modelContext.save()
            refresh()
        } catch {
            lastErrorMessage = "フォルダを削除できませんでした。"
        }
    }

    func renameFolder(_ folder: FolderRecord, to name: String) {
        folder.name = name
        try? modelContext?.save()
        refreshFolders()
    }

    // MARK: - Refresh

    func refresh() {
        guard let modelContext else { return }

        do {
            var descriptor = FetchDescriptor<ArchivedMinutesRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            descriptor.fetchLimit = 300
            let records = try modelContext.fetch(descriptor)
            items = records.compactMap { $0.decodedResult() }
            folderAssignments = Dictionary(
                uniqueKeysWithValues: records.compactMap { record -> (String, String)? in
                    guard let fid = record.folderID else { return nil }
                    return (record.recordID, fid)
                }
            )
        } catch {
            lastErrorMessage = "保存済み議事録を読み込めませんでした。"
        }

        refreshFolders()
    }

    private func refreshFolders() {
        guard let modelContext else { return }

        do {
            let descriptor = FetchDescriptor<FolderRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            folders = try modelContext.fetch(descriptor)
        } catch {
            lastErrorMessage = "フォルダを読み込めませんでした。"
        }
    }
}
