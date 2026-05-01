import SwiftUI

struct ArchiveView: View {
    @EnvironmentObject private var archiveStore: ArchiveStore
    @State private var query = ""

    var body: some View {
        ZStack {
            KMColor.background.ignoresSafeArea()

            List {
                ForEach(archiveStore.search(query)) { item in
                    NavigationLink {
                        ResultView(result: item)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.title)
                                .font(.headline)
                            Text(item.shareSummary.text)
                                .font(.subheadline)
                                .foregroundStyle(KMColor.secondaryText)
                                .lineLimit(2)
                            Text("\(item.category.rawValue) ・ \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundStyle(KMColor.tertiaryText)
                        }
                        .padding(.vertical, 6)
                    }
                    .swipeActions {
                        Button("削除", role: .destructive) {
                            archiveStore.delete(item)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("保存済み議事録")
        .searchable(text: $query, prompt: "タイトルや概要を検索")
        .onAppear {
            archiveStore.refresh()
        }
        .overlay {
            if archiveStore.items.isEmpty {
                ContentUnavailableView("保存済み議事録はありません", systemImage: "archivebox", description: Text("生成結果画面から保存できます。"))
            }
        }
    }
}
