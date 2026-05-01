import SwiftUI
import UIKit

struct ResultView: View {
    @EnvironmentObject private var archiveStore: ArchiveStore
    @State private var selectedTab: ResultTab = .share
    @State private var didSave = false
    let result: MinutesResult

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
                    case .log:
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
        .alert("保存しました", isPresented: $didSave) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: KMSpacing.xs) {
            Text(result.title)
                .font(.title2.bold())
            Text("\(result.category.rawValue) ・ \(result.costInfo.inputLength)文字 ・ \(result.costInfo.processingMode.rawValue)")
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
                archiveStore.save(result)
                didSave = true
            } label: {
                Label("保存", systemImage: "tray.and.arrow.down")
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

private enum ResultTab: String, CaseIterable, Identifiable {
    case share
    case minutes
    case log

    var id: String { rawValue }

    var title: String {
        switch self {
        case .share:
            return "共有版"
        case .minutes:
            return "議事録"
        case .log:
            return "全量ログ"
        }
    }
}

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

private struct FullLogView: View {
    let entries: [FullLogEntry]

    var body: some View {
        VStack(spacing: KMSpacing.md) {
            ForEach(entries) { entry in
                KMCard {
                    VStack(alignment: .leading, spacing: KMSpacing.sm) {
                        Text(entry.speaker)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(KMColor.moss)
                        Text(entry.text)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

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
