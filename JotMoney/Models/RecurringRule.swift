import Foundation
import SwiftData

@Model
final class RecurringRule {
    var id: UUID = UUID()
    var merchantRaw: String = ""
    var merchantKey: String = ""
    var amountCents: Int64 = 0
    var typeRaw: String = EntryType.expense.rawValue
    var categoryKey: String = DefaultCategoryKey.bills
    var accountID: UUID = UUID()
    var cadenceRaw: String = CadenceType.monthly.rawValue
    var anchorDate: Date = Date()
    var lastGeneratedDate: Date?
    var isActive: Bool = true
    var createdAt: Date = Date()

    init(
        merchantRaw: String = "",
        amountCents: Int64 = 0,
        type: EntryType = .expense,
        categoryKey: String = DefaultCategoryKey.bills,
        accountID: UUID = UUID(),
        cadence: CadenceType = .monthly,
        anchorDate: Date = Date()
    ) {
        self.id = UUID()
        self.merchantRaw = merchantRaw
        self.merchantKey = merchantRaw.lowercased()
        self.amountCents = amountCents
        self.typeRaw = type.rawValue
        self.categoryKey = categoryKey
        self.accountID = accountID
        self.cadenceRaw = cadence.rawValue
        self.anchorDate = anchorDate
    }

    var cadence: CadenceType {
        get { CadenceType(rawValue: cadenceRaw) ?? .monthly }
        set { cadenceRaw = newValue.rawValue }
    }

    var type: EntryType {
        get { EntryType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }
}
