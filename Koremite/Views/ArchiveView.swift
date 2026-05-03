import SwiftUI

enum ArchiveDest: Hashable {
    case all
    case unfoldered
    case folder(String, String) // folderID, name
}

struct ArchiveView: View {
    @EnvironmentObject private var archiveStore: ArchiveStore
    @State private var query = ""
    @State private var committedQuery = ""
    @State private var showNewFolderSheet = false
    @State private var folderToDelete: FolderRecord?
    @State private var folderToRename: FolderRecord?
    @State private var showDeleteConfirm = false
    @State private var showRenameAlert = false
    @State private var renameDraft = ""

    var body: some View {
        // ArchiveBrowserContent is a separate child struct so it can read
        // @Environment(\.isSearching), which is only available inside .searchable.
        // isSearching becomes true when the user TAPS the search bar (before any typing),
        // so the List switches from folder-hierarchy to flat-results exactly once at that
        // moment — not on every keystroke — preventing keyboard-focus loss.
        ArchiveBrowserContent(
            query: committedQuery,
            onNewFolder: { showNewFolderSheet = true },
            onDeleteFolder: { folder in
                folderToDelete = folder
                showDeleteConfirm = true
            },
            onRenameFolder: { folder in
                folderToRename = folder
                renameDraft = folder.name
                showRenameAlert = true
            }
        )
        .navigationTitle("保存済み議事録")
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showNewFolderSheet = true } label: {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .navigationDestination(for: ArchiveDest.self) { dest in
            ArchiveItemListView(dest: dest)
                .environmentObject(archiveStore)
        }
        .navigationDestination(for: MinutesResult.self) { result in
            ResultView(result: result)
                .environmentObject(archiveStore)
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NewFolderSheet { name in archiveStore.createFolder(name: name) }
        }
        .confirmationDialog(
            "「\(folderToDelete?.name ?? "")」を削除",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("フォルダのみ削除（中身は保持）", role: .destructive) {
                if let folder = folderToDelete { archiveStore.deleteFolder(folder, removeItems: false) }
            }
            Button("フォルダと議事録をすべて削除", role: .destructive) {
                if let folder = folderToDelete { archiveStore.deleteFolder(folder, removeItems: true) }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert("名前を変更", isPresented: $showRenameAlert) {
            TextField("フォルダ名", text: $renameDraft)
            Button("変更") {
                let name = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty, let folder = folderToRename {
                    archiveStore.renameFolder(folder, to: name)
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .onAppear { archiveStore.refresh() }
    }
}

// MARK: - Browser Content

private struct ArchiveBrowserContent: View {
    let query: String
    let onNewFolder: () -> Void
    let onDeleteFolder: (FolderRecord) -> Void
    let onRenameFolder: (FolderRecord) -> Void

    @EnvironmentObject private var archiveStore: ArchiveStore
    @Environment(\.isSearching) private var isSearching

    private var searchResults: [MinutesResult] { archiveStore.search(query) }

    private func itemCount(inFolder folderID: String) -> Int {
        archiveStore.items.filter { archiveStore.folderAssignments[$0.id.uuidString] == folderID }.count
    }

    private var unfolderedCount: Int {
        archiveStore.items.filter { archiveStore.folderAssignments[$0.id.uuidString] == nil }.count
    }

    private func folderName(for item: MinutesResult) -> String? {
        guard let fid = archiveStore.folderAssignments[item.id.uuidString] else { return nil }
        return archiveStore.folders.first { $0.folderID == fid }?.name
    }

    var body: some View {
        ZStack {
            KMColor.background.ignoresSafeArea()
            List {
                if isSearching {
                    searchContent
                } else {
                    folderContent
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if searchResults.isEmpty {
            ContentUnavailableView(
                query.isEmpty ? "保存済み議事録はありません" : "検索結果なし",
                systemImage: query.isEmpty ? "archivebox" : "magnifyingglass",
                description: Text(query.isEmpty ? "生成結果画面から保存できます。" : "別のキーワードで試してください。")
            )
            .listRowBackground(Color.clear)
        } else {
            ForEach(searchResults) { item in
                NavigationLink(value: item) {
                    ArchiveRowView(item: item, folderName: folderName(for: item))
                }
                .swipeActions(edge: .trailing) {
                    Button("削除", role: .destructive) { archiveStore.delete(item) }
                }
            }
        }
    }

    @ViewBuilder
    private var folderContent: some View {
        Section {
            ForEach(archiveStore.folders) { folder in
                NavigationLink(value: ArchiveDest.folder(folder.folderID, folder.name)) {
                    HStack(spacing: 12) {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(KMColor.moss)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(folder.name)
                                .font(.body.weight(.semibold))
                            Text("\(itemCount(inFolder: folder.folderID))件")
                                .font(.caption)
                                .foregroundStyle(KMColor.tertiaryText)
                        }
                        Spacer()
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("削除", role: .destructive) { onDeleteFolder(folder) }
                }
                .contextMenu {
                    Button("名前を変更") { onRenameFolder(folder) }
                    Button("削除", role: .destructive) { onDeleteFolder(folder) }
                }
            }
            Button { onNewFolder() } label: {
                Label("新規フォルダ", systemImage: "folder.badge.plus")
                    .foregroundStyle(KMColor.moss)
            }
        }

        Section("一覧") {
            NavigationLink(value: ArchiveDest.all) {
                Label("すべての議事録（\(archiveStore.items.count)件）", systemImage: "list.bullet")
            }
            NavigationLink(value: ArchiveDest.unfoldered) {
                Label("フォルダなし（\(unfolderedCount)件）", systemImage: "tray")
            }
        }

        if !archiveStore.items.isEmpty {
            Section("最近") {
                ForEach(archiveStore.items.prefix(5)) { item in
                    NavigationLink(value: item) {
                        ArchiveRowView(item: item, folderName: folderName(for: item))
                    }
                }
            }
        }

        if archiveStore.items.isEmpty {
            ContentUnavailableView(
                "保存済み議事録はありません",
                systemImage: "archivebox",
                description: Text("生成結果画面から保存できます。")
            )
            .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Row

struct ArchiveRowView: View {
    let item: MinutesResult
    var folderName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title).font(.headline)
            Text(item.shareSummary.text)
                .font(.subheadline)
                .foregroundStyle(KMColor.secondaryText)
                .lineLimit(2)
            HStack(spacing: 4) {
                Text("\(item.category.rawValue) ・ \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                if let folderName {
                    Text("・")
                    Image(systemName: "folder").font(.caption2).foregroundStyle(KMColor.moss)
                    Text(folderName).foregroundStyle(KMColor.moss)
                }
            }
            .font(.caption)
            .foregroundStyle(KMColor.tertiaryText)
        }
        .padding(.vertical, 6)
    }
}

// MARK: - New Folder Sheet

struct NewFolderSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onCreate: (String) -> Void
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("フォルダ名", text: $name).focused($focused)
                }
            }
            .navigationTitle("新規フォルダ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !t.isEmpty { onCreate(t) }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}
