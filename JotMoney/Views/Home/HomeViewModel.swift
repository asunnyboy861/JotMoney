import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var safeToSpendCents: Int64 = 0
    @Published var availableCents: Int64 = 0
    @Published var committedCents: Int64 = 0
    @Published var progress: Double = 0
    @Published var todayEntries: [LedgerEntry] = []
    @Published var todaySpendCents: Int64 = 0
    @Published var monthSpendCents: Int64 = 0
    @Published var netWorthCents: Int64 = 0
    @Published var daysLeft: Int = 0

    func update(
        accounts: [Account],
        entries: [LedgerEntry],
        budgets: [Budget],
        rules: [RecurringRule],
        plans: [InstallmentPlan],
        mode: SpendMode
    ) {
        let result = SafeToSpendEngine.compute(
            accounts: accounts,
            entries: entries,
            budgets: budgets,
            rules: rules,
            plans: plans,
            mode: mode
        )
        safeToSpendCents = result.amountCents
        availableCents = result.availableCents
        committedCents = result.committedCents
        progress = result.progress
        daysLeft = result.daysLeft
        todayEntries = BalanceEngine.entries(on: Date(), from: entries)
        todaySpendCents = BalanceEngine.dayTotal(entries: entries)
        monthSpendCents = BalanceEngine.monthTotal(entries: entries, type: .expense)
        netWorthCents = BalanceEngine.netWorth(accounts: accounts, entries: entries)
        AppGroupSnapshot.writeSafeToSpend(result.amountCents)
    }
}
