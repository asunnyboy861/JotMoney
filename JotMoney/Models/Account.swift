import Foundation
import SwiftData

@Model
final class Account {
    var id: UUID = UUID()
    var name: String = ""
    var normalizedKey: String = ""
    var kindRaw: String = AccountKind.checking.rawValue
    var currencyCode: String = "USD"
    var openingBalanceCents: Int64 = 0
    var aprBps: Int = 0
    var isArchived: Bool = false
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    init(name: String = "", kind: AccountKind = .checking, openingBalanceCents: Int64 = 0) {
        self.id = UUID()
        self.name = name
        self.normalizedKey = Account.normalize(name)
        self.kindRaw = kind.rawValue
        self.openingBalanceCents = openingBalanceCents
    }

    var kind: AccountKind {
        get { AccountKind(rawValue: kindRaw) ?? .checking }
        set { kindRaw = newValue.rawValue }
    }

    var isLiability: Bool { kind.isLiability }

    static func normalize(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
