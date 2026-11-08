import Foundation
import SwiftData

@Model
final class Budget {
    var id: UUID = UUID()
    var categoryKey: String = DefaultCategoryKey.other
    var limitCents: Int64 = 0
    var createdAt: Date = Date()
    var isArchived: Bool = false

    init(categoryKey: String = DefaultCategoryKey.other, limitCents: Int64 = 0) {
        self.id = UUID()
        self.categoryKey = categoryKey
        self.limitCents = limitCents
    }
}
