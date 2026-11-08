import Foundation
import SwiftData

@Model
final class AuditLogEntry {
    var id: UUID = UUID()
    var action: String = ""
    var entityID: String = ""
    var detail: String = ""
    var createdAt: Date = Date()

    init(action: String = "", entityID: String = "", detail: String = "") {
        self.id = UUID()
        self.action = action
        self.entityID = entityID
        self.detail = detail
        self.createdAt = Date()
    }
}
