import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var archiveStore: ArchiveStore

    var body: some View {
        TabView {
            NavigationStack {
                InputView()
            }
            .tabItem {
                Label("作成", systemImage: "square.and.pencil")
            }

            NavigationStack {
                ArchiveView()
            }
            .tabItem {
                Label("保存済み", systemImage: "archivebox")
            }
        }
        .tint(KMColor.moss)
        .task {
            archiveStore.configure(modelContext: modelContext)
        }
    }
}
