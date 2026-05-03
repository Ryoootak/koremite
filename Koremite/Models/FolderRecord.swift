import Foundation
import SwiftData

@Model
final class FolderRecord {
    @Attribute(.unique) var folderID: String
    var name: String
    var createdAt: Date

    init(name: String, folderID: String = UUID().uuidString) {
        self.folderID = folderID
        self.name = name
        self.createdAt = Date()
    }
}
