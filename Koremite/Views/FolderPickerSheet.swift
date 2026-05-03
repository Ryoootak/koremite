import SwiftUI

struct FolderPickerSheet: View {
    @EnvironmentObject private var archiveStore: ArchiveStore
    @Environment(\.dismiss) private var dismiss
    let currentFolderID: String?
    let onSelect: (String?) -> Void

    @State private var showNewFolderField = false
    @State private var newFolderName = ""
    @FocusState private var newFolderFieldFocused: Bool

    var body: some View {
        NavigationStack {
            List {
                Section {
                    folderRow(
                        label: "フォルダなし",
                        systemImage: "tray",
                        folderID: nil
                    )
                }

                Section("フォルダ") {
                    ForEach(archiveStore.folders) { folder in
                        folderRow(
                            label: folder.name,
                            systemImage: "folder",
                            folderID: folder.folderID
                        )
                    }

                    if showNewFolderField {
                        HStack {
                            Image(systemName: "folder.badge.plus")
                                .foregroundStyle(KMColor.moss)
                            TextField("フォルダ名", text: $newFolderName)
                                .focused($newFolderFieldFocused)
                                .onSubmit { commitNewFolder() }
                            if !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button("作成") { commitNewFolder() }
                                    .foregroundStyle(KMColor.moss)
                            }
                        }
                    }

                    Button {
                        showNewFolderField = true
                        newFolderFieldFocused = true
                    } label: {
                        Label("新規フォルダを作成", systemImage: "folder.badge.plus")
                            .foregroundStyle(KMColor.moss)
                    }
                }
            }
            .navigationTitle("保存先フォルダ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func folderRow(label: String, systemImage: String, folderID: String?) -> some View {
        Button {
            onSelect(folderID)
            dismiss()
        } label: {
            HStack {
                Label(label, systemImage: systemImage)
                    .foregroundStyle(.primary)
                Spacer()
                if folderID == currentFolderID {
                    Image(systemName: "checkmark")
                        .foregroundStyle(KMColor.moss)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func commitNewFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let newID = UUID().uuidString
        archiveStore.createFolder(name: name, folderID: newID)
        onSelect(newID)
        dismiss()
    }
}
