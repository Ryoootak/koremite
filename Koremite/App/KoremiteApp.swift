import SwiftUI
import SwiftData

@main
struct KoremiteApp: App {
    @StateObject private var archiveStore = ArchiveStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(archiveStore)
        }
        .modelContainer(for: ArchivedMinutesRecord.self)
    }
}
