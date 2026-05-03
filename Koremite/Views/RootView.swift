import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var archiveStore: ArchiveStore

    @State private var selectedTab = 0
    @State private var archivePath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                InputView()
            }
            .tabItem {
                Label("作成", systemImage: "square.and.pencil")
            }
            .tag(0)

            NavigationStack(path: $archivePath) {
                ArchiveView()
            }
            .tabItem {
                Label("保存済み", systemImage: "archivebox")
            }
            .tag(1)
        }
        .tint(KMColor.moss)
        .onChange(of: selectedTab) { old, new in
            // Reset archive navigation when returning to the archive tab
            if new == 1 && old != 1 {
                archivePath = NavigationPath()
            }
        }
        .task {
            archiveStore.configure(modelContext: modelContext)
        }
    }
}
