import Foundation
import SwiftData

@Model
final class LedgerEntry {
    var id: UUID = UUID()
    var idempotencyKey: String = ""
    var date: Date = Date()
    var localTimeZoneID: String = ""
    var amountCents: Int64 = 0
    var typeRaw: String = EntryType.expense.rawValue
    var merchantRaw: String = ""
    var merchantKey: String = ""
    var categoryKey: String = DefaultCategoryKey.other
    var accountID: UUID = UUID()
    var sourceRaw: String = EntrySource.manual.rawValue
    var ruleID: UUID?
    var installmentPlanID: UUID?
    var pendingOf: UUID?
    var note: String = ""
    var receiptImagePath: String = ""
    var createdAt: Date = Date()
    var isArchived: Bool = false

    init(
        amountCents: Int64 = 0,
        type: EntryType = .expense,
        merchantRaw: String = "",
        merchantKey: String = "",
        categoryKey: String = DefaultCategoryKey.other,
        accountID: UUID = UUID(),
        date: Date = Date(),
        source: EntrySource = .manual
    ) {
        self.id = UUID()
        self.idempotencyKey = LedgerEntry.makeKey()
        self.amountCents = amountCents
        self.typeRaw = type.rawValue
        self.merchantRaw = merchantRaw
        self.merchantKey = merchantKey.isEmpty ? merchantRaw.lowercased() : merchantKey
        self.categoryKey = categoryKey
        self.accountID = accountID
        self.date = date
        self.localTimeZoneID = TimeZone.current.identifier
        self.sourceRaw = source.rawValue
        self.createdAt = Date()
    }

    var type: EntryType {
        get { EntryType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    var source: EntrySource {
        get { EntrySource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    var signedCents: Int64 {
        type == .income ? amountCents : -amountCents
    }

    var displayMerchant: String {
        merchantRaw.isEmpty ? "Unknown" : merchantRaw
    }

    static func makeKey() -> String {
        UUID().uuidString.lowercased()
    }

    static func normalizeMerchant(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "  ", with: " ")
    }
}
