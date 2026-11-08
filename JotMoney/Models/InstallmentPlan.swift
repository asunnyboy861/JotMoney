import Foundation
import SwiftData

@Model
final class InstallmentPlan {
    var id: UUID = UUID()
    var merchantRaw: String = ""
    var merchantKey: String = ""
    var categoryKey: String = DefaultCategoryKey.shopping
    var totalCents: Int64 = 0
    var perPeriodCents: Int64 = 0
    var periodCount: Int = 4
    var firstChargeDate: Date = Date()
    var cadenceRaw: String = CadenceType.biweekly.rawValue
    var accountID: UUID = UUID()
    var generatedCount: Int = 0
    var createdAt: Date = Date()
    var isArchived: Bool = false

    init(
        merchantRaw: String = "",
        totalCents: Int64 = 0,
        perPeriodCents: Int64 = 0,
        periodCount: Int = 4,
        firstChargeDate: Date = Date(),
        cadence: CadenceType = .biweekly,
        accountID: UUID = UUID(),
        categoryKey: String = DefaultCategoryKey.shopping
    ) {
        self.id = UUID()
        self.merchantRaw = merchantRaw
        self.merchantKey = merchantRaw.lowercased()
        self.totalCents = totalCents
        self.perPeriodCents = perPeriodCents
        self.periodCount = periodCount
        self.firstChargeDate = firstChargeDate
        self.cadenceRaw = cadence.rawValue
        self.accountID = accountID
        self.categoryKey = categoryKey
    }

    var cadence: CadenceType {
        get { CadenceType(rawValue: cadenceRaw) ?? .biweekly }
        set { cadenceRaw = newValue.rawValue }
    }
}
