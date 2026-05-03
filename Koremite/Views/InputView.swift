import SwiftUI

struct InputView: View {
    @EnvironmentObject private var archiveStore: ArchiveStore
    @StateObject private var viewModel = MinutesInputViewModel()
    @State private var showFolderPicker = false

    var body: some View {
        ZStack {
            KMColor.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: KMSpacing.lg) {
                    header
                    transcriptCard
                    speakerCard
                    folderCard
                    focusCard
                    privacyNotice
                    generateButton
                }
                .padding(KMSpacing.lg)
            }
        }
        .navigationDestination(item: $viewModel.result) { result in
            ResultView(result: result, suggestedFolderID: viewModel.selectedFolderID)
        }
        .sheet(isPresented: $showFolderPicker) {
            FolderPickerSheet(currentFolderID: viewModel.selectedFolderID) { folderID in
                let folderName = archiveStore.folders.first { $0.folderID == folderID }?.name
                selectFolder(id: folderID, name: folderName)
            }
            .environmentObject(archiveStore)
        }
        .overlay {
            if viewModel.isGenerating {
                LoadingView()
            }
        }
        .alert("生成できませんでした", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("閉じる", role: .cancel) {}
            Button("リトライ") {
                Task { await viewModel.generate(reusing: archiveStore) }
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: KMSpacing.xs) {
            Text("Koremite")
                .font(.largeTitle.bold())
                .foregroundStyle(KMColor.text)
            Text("文字起こしを貼り付けて、送れる議事録に整えます。")
                .font(.subheadline)
                .foregroundStyle(KMColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var transcriptCard: some View {
        KMCard {
            VStack(alignment: .leading, spacing: KMSpacing.md) {
                Text("文字起こし")
                    .font(.headline)
                TextEditor(text: $viewModel.transcript)
                    .frame(minHeight: 190)
                    .scrollContentBackground(.hidden)
                    .background(KMColor.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if viewModel.transcript.isEmpty {
                            Text("ボイスメモの文字起こしをここに貼り付け")
                                .foregroundStyle(KMColor.tertiaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 10)
                                .allowsHitTesting(false)
                        }
                    }

                HStack {
                    Text("\(viewModel.characterCount) / \(viewModel.maxInputCharacters)文字")
                        .foregroundStyle(viewModel.isOverLimit ? .red : KMColor.tertiaryText)
                    Spacer()
                    Text(viewModel.costHint)
                        .foregroundStyle(viewModel.isOverLimit ? .red : KMColor.secondaryText)
                        .multilineTextAlignment(.trailing)
                }
                .font(.caption)
            }
        }
    }

    private var speakerCard: some View {
        KMCard {
            VStack(alignment: .leading, spacing: KMSpacing.sm) {
                Text("話者候補")
                    .font(.headline)
                TextField("自分, 相手", text: $viewModel.speakersText)
                    .textFieldStyle(.roundedBorder)
                Text("カンマ区切りで入力できます。話者が不明な場合は仮ラベルで整理します。")
                    .font(.caption)
                    .foregroundStyle(KMColor.secondaryText)
            }
        }
    }

    private var folderCard: some View {
        KMCard {
            VStack(alignment: .leading, spacing: KMSpacing.md) {
                HStack {
                    Label("保存先フォルダ", systemImage: "folder")
                        .font(.headline)
                    Spacer()
                    Button {
                        showFolderPicker = true
                    } label: {
                        Label("選択", systemImage: "folder.badge.plus")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(KMColor.moss)
                }

                Text("ここで選んだフォルダに、生成後の保存先が初期設定されます。")
                    .font(.caption)
                    .foregroundStyle(KMColor.secondaryText)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: KMSpacing.sm)], alignment: .leading, spacing: KMSpacing.sm) {
                    folderChip(name: "フォルダなし", systemImage: "tray", folderID: nil)
                    ForEach(archiveStore.folders) { folder in
                        folderChip(name: folder.name, systemImage: "folder", folderID: folder.folderID)
                    }
                }

                if archiveStore.folders.isEmpty {
                    quickFolderSuggestions
                }
            }
        }
    }

    private var quickFolderSuggestions: some View {
        VStack(alignment: .leading, spacing: KMSpacing.sm) {
            Text("よく使うフォルダを作成")
                .font(.caption.weight(.semibold))
                .foregroundStyle(KMColor.tertiaryText)
            HStack(spacing: KMSpacing.sm) {
                ForEach(["住宅", "仕事", "家庭"], id: \.self) { name in
                    Button {
                        archiveStore.createFolder(name: name)
                        if let folder = archiveStore.folders.first(where: { $0.name == name }) {
                            selectFolder(id: folder.folderID, name: folder.name)
                        }
                    } label: {
                        Label(name, systemImage: "folder.badge.plus")
                            .font(.caption.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(KMColor.moss)
                }
            }
        }
    }

    private func folderChip(name: String, systemImage: String, folderID: String?) -> some View {
        Button {
            selectFolder(id: folderID, name: name)
        } label: {
            HStack(spacing: KMSpacing.xs) {
                Image(systemName: systemImage)
                Text(name)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if viewModel.selectedFolderID == folderID {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, KMSpacing.sm)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(viewModel.selectedFolderID == folderID ? KMColor.moss.opacity(0.14) : KMColor.groupedBackground)
            .foregroundStyle(viewModel.selectedFolderID == folderID ? KMColor.moss : KMColor.text)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(viewModel.selectedFolderID == folderID ? KMColor.moss.opacity(0.35) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func selectFolder(id: String?, name: String?) {
        viewModel.selectedFolderID = id
        viewModel.updateCategoryFromFolderName(id == nil ? nil : name)
    }


    private var focusCard: some View {
        KMCard {
            VStack(alignment: .leading, spacing: KMSpacing.md) {
                Text("重視ポイント")
                    .font(.headline)
                chipGrid(FocusPoint.allCases.map(\.rawValue)) { title in
                    let point = FocusPoint(rawValue: title) ?? .decisions
                    KMChip(title: title, isSelected: viewModel.selectedFocusPoints.contains(point)) {
                        viewModel.toggle(point)
                    }
                }
            }
        }
    }

    private var privacyNotice: some View {
        Text("生成時、貼り付けた文字起こしテキストはAI処理のためKoremiteのサーバーへ送信されます。音声の収録やアップロードは行いません。")
            .font(.footnote)
            .foregroundStyle(KMColor.secondaryText)
            .padding(.horizontal, KMSpacing.sm)
    }

    private var generateButton: some View {
        KMPrimaryButton(title: "議事録を生成", systemImage: "sparkles", isDisabled: !viewModel.canGenerate) {
            Task { await viewModel.generate(reusing: archiveStore) }
        }
        .padding(.bottom, KMSpacing.xl)
    }

    private func chipGrid<Data: RandomAccessCollection, Content: View>(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) -> some View where Data.Element: Hashable {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: KMSpacing.sm)], alignment: .leading, spacing: KMSpacing.sm) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}
