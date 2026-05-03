import SwiftUI

struct ArchiveItemListView: View {
    let dest: ArchiveDest
    @EnvironmentObject private var archiveStore: ArchiveStore
    @State private var query = ""
    @State private var committedQuery = ""

    private var navigationTitle: String {
        switch dest {
        case .all: return "全て"
        case .unfoldered: return "フォルダなし"
        case .folder(_, let name): return name
        }
    }

    private var baseItems: [MinutesResult] {
        switch dest {
        case .all:
            return archiveStore.items
        case .unfoldered:
            return archiveStore.items.filter { archiveStore.folderAssignments[$0.id.uuidString] == nil }
        case .folder(let folderID, _):
            return archiveStore.items.filter { archiveStore.folderAssignments[$0.id.uuidString] == folderID }
        }
    }

    private var displayItems: [MinutesResult] {
        let trimmed = committedQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return baseItems }
        return baseItems.filter { result in
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

    private func folderName(for item: MinutesResult) -> String? {
        guard dest == .all,
              let fid = archiveStore.folderAssignments[item.id.uuidString]
        else { return nil }
        return archiveStore.folders.first { $0.folderID == fid }?.name
    }

    var body: some View {
        ZStack {
            KMColor.background.ignoresSafeArea()

            List {
                ForEach(displayItems) { item in
                    NavigationLink(value: item) {
                        ArchiveRowView(item: item, folderName: folderName(for: item))
                    }
                    .swipeActions(edge: .trailing) {
                        Button("削除", role: .destructive) {
                            archiveStore.delete(item)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .overlay {
                if displayItems.isEmpty {
                    if committedQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        ContentUnavailableView(
                            "議事録がありません",
                            systemImage: "tray",
                            description: Text("議事録を生成してから保存すると表示されます。")
                        )
                    } else {
                        ContentUnavailableView(
                            "検索結果なし",
                            systemImage: "magnifyingglass",
                            description: Text("別のキーワードで試してください。")
                        )
                    }
                }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "タイトルや概要を検索")
        .onSubmit(of: .search) {
            committedQuery = query
        }
        .onChange(of: query) { _, newValue in
            if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                committedQuery = ""
            }
        }
        // Register here too: when this view is pushed, it cannot reach ArchiveView's destinations
        .navigationDestination(for: MinutesResult.self) { result in
            ResultView(result: result)
                .environmentObject(archiveStore)
        }
    }
}
