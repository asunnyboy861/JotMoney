import Foundation
import SwiftData

@Model
final class InterestEntry {
    var id: UUID = UUID()
    var accountID: UUID = UUID()
    var periodStart: Date = Date()
    var periodEnd: Date = Date()
    var accruedCents: Int64 = 0
    var correctedCents: Int64?
    var note: String = ""
    var createdAt: Date = Date()

    init(accountID: UUID = UUID(), periodStart: Date = Date(), periodEnd: Date = Date(), accruedCents: Int64 = 0) {
        self.id = UUID()
        self.accountID = accountID
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.accruedCents = accruedCents
    }

    var effectiveCents: Int64 { correctedCents ?? accruedCents }
}
