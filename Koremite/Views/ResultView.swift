import SwiftUI
import UIKit

struct ResultView: View {
    @EnvironmentObject private var archiveStore: ArchiveStore
    @State private var selectedTab: ResultTab = .share
    @State private var showFolderPicker = false
    @State private var didSave = false
    @State private var saveAlertTitle = "保存しました"
    let result: MinutesResult

    private var currentFolderID: String? {
        archiveStore.folderAssignments[result.id.uuidString]
    }

    private var currentFolderName: String? {
        guard let fid = currentFolderID else { return nil }
        return archiveStore.folders.first { $0.folderID == fid }?.name
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            KMColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: KMSpacing.lg) {
                    header
                    Picker("表示", selection: $selectedTab) {
                        ForEach(ResultTab.allCases) { tab in
                            Text(tab.title).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)

                    switch selectedTab {
                    case .share:
                        ShareSummaryView(summary: result.shareSummary)
                    case .minutes:
                        DetailedMinutesView(minutes: result.detailedMinutes)
                    case .fullLog:
                        FullLogView(entries: result.fullLog)
                    }

                    Spacer(minLength: 96)
                }
                .padding(KMSpacing.lg)
            }

            actionBar
        }
        .navigationTitle("生成結果")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerSheet(currentFolderID: currentFolderID) { selectedFolderID in
                if archiveStore.isSaved(result) {
                    saveAlertTitle = "フォルダを変更しました"
                    archiveStore.setFolder(for: result, folderID: selectedFolderID)
                } else {
                    saveAlertTitle = "保存しました"
                    archiveStore.save(result, folderID: selectedFolderID)
                }
                didSave = true
            }
            .environmentObject(archiveStore)
        }
        .alert(saveAlertTitle, isPresented: $didSave) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: KMSpacing.xs) {
            Text(result.title)
                .font(.title2.bold())
            HStack(spacing: 4) {
                Text("\(result.category.rawValue) ・ \(result.costInfo.inputLength)文字 ・ \(result.costInfo.processingMode.rawValue)")
                if let folderName = currentFolderName {
                    Text("・")
                    Image(systemName: "folder")
                        .font(.caption)
                    Text(folderName)
                }
            }
            .font(.caption)
            .foregroundStyle(KMColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionBar: some View {
        HStack(spacing: KMSpacing.sm) {
            Button {
                UIPasteboard.general.string = result.copyText
            } label: {
                Label("議事録", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)

            ShareLink(item: result.shareSummary.text) {
                Label("送る", systemImage: "square.and.arrow.up")
            }
            .buttonStyle(.bordered)

            Button {
                showFolderPicker = true
            } label: {
                Label(archiveStore.isSaved(result) ? "フォルダ" : "保存", systemImage: archiveStore.isSaved(result) ? "folder" : "tray.and.arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .tint(KMColor.moss)
        }
        .font(.subheadline.weight(.semibold))
        .padding(KMSpacing.md)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Tabs

private enum ResultTab: String, CaseIterable, Identifiable {
    case share
    case minutes
    case fullLog

    var id: String { rawValue }

    var title: String {
        switch self {
        case .share: return "共有版"
        case .minutes: return "議事録"
        case .fullLog: return "全量ログ"
        }
    }
}

// MARK: - Share Summary

private struct ShareSummaryView: View {
    let summary: ShareSummary

    var body: some View {
        VStack(spacing: KMSpacing.lg) {
            KMCard {
                Text(summary.text)
                    .font(.body)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            ListBlock(title: "決定事項", items: summary.decisions)
            TodoBlock(items: summary.todos)
            ListBlock(title: "確認事項", items: summary.confirmationPoints)
        }
    }
}

// MARK: - Detailed Minutes

private struct DetailedMinutesView: View {
    let minutes: DetailedMinutes

    var body: some View {
        VStack(spacing: KMSpacing.lg) {
            KMCard {
                VStack(alignment: .leading, spacing: KMSpacing.sm) {
                    Text("概要").font(.headline)
                    Text(minutes.overview).lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            ListBlock(title: "論点", items: minutes.topics)
            ListBlock(title: "決定事項", items: minutes.decisions)
            ListBlock(title: "未決事項", items: minutes.openIssues)
            TodoBlock(items: minutes.todos)
            ListBlock(title: "重要な発言", items: minutes.importantRemarks)
            ListBlock(title: "次回に向けたメモ", items: minutes.nextMeetingNotes)
        }
    }
}

// MARK: - Full Log

private struct FullLogView: View {
    let entries: [FullLogEntry]
    @State private var query = ""
    @State private var committedQuery = ""

    private var filtered: [FullLogEntry] {
        let trimmed = committedQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter {
            TextUtilities.matchesFuzzy("\($0.speaker) \($0.text)", query: trimmed)
        }
    }

    var body: some View {
        VStack(spacing: KMSpacing.sm) {
            // Search bar
            HStack(spacing: KMSpacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(KMColor.tertiaryText)
                TextField("発言・話者を検索", text: $query)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .onSubmit {
                        committedQuery = query
                    }
                if !query.isEmpty {
                    Button {
                        query = ""
                        committedQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(KMColor.tertiaryText)
                    }
                }
            }
            .padding(KMSpacing.sm)
            .background(KMColor.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .onChange(of: query) { _, newValue in
                if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    committedQuery = ""
                }
            }

            if entries.isEmpty {
                KMCard {
                    Text("全量ログがありません")
                        .foregroundStyle(KMColor.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if filtered.isEmpty {
                KMCard {
                    Text("検索結果なし")
                        .foregroundStyle(KMColor.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(filtered) { entry in
                    KMCard {
                        VStack(alignment: .leading, spacing: KMSpacing.xs) {
                            Text(entry.speaker)
                                .font(.caption.bold())
                                .foregroundStyle(KMColor.moss)
                            Text(entry.text)
                                .font(.body)
                                .lineSpacing(4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Shared Components

private struct ListBlock: View {
    let title: String
    let items: [String]

    var body: some View {
        KMCard {
            VStack(alignment: .leading, spacing: KMSpacing.sm) {
                Text(title).font(.headline)
                if items.isEmpty {
                    Text("該当なし")
                        .foregroundStyle(KMColor.tertiaryText)
                } else {
                    ForEach(items, id: \.self) { item in
                        Text("・\(item)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

private struct TodoBlock: View {
    let items: [TodoItem]

    var body: some View {
        KMCard {
            VStack(alignment: .leading, spacing: KMSpacing.sm) {
                Text("TODO").font(.headline)
                if items.isEmpty {
                    Text("該当なし")
                        .foregroundStyle(KMColor.tertiaryText)
                } else {
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.task)
                            Text([item.owner, item.due].compactMap { $0 }.joined(separator: " ・ "))
                                .font(.caption)
                                .foregroundStyle(KMColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}
