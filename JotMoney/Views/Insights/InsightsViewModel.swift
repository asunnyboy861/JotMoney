import Foundation

struct CategorySlice: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let amountCents: Int64
    let share: Double
}

@MainActor
final class InsightsViewModel: ObservableObject {
    @Published var monthSpendCents: Int64 = 0
    @Published var monthIncomeCents: Int64 = 0
    @Published var slices: [CategorySlice] = []
    @Published var netWorthCents: Int64 = 0
    @Published var forecast: [ForecastPoint] = []
    @Published var radar: [SubscriptionSuspicion] = []

    func update(
        accounts: [Account],
        entries: [LedgerEntry],
        rules: [RecurringRule],
        plans: [InstallmentPlan]
    ) {
        monthSpendCents = BalanceEngine.monthTotal(entries: entries, type: .expense)
        monthIncomeCents = BalanceEngine.monthTotal(entries: entries, type: .income)
        netWorthCents = BalanceEngine.netWorth(accounts: accounts, entries: entries)

        let totals = BalanceEngine.categoryTotals(entries: entries)
        let sum = max(1, totals.values.reduce(Int64(0), +))
        slices = totals
            .map { key, value in
                CategorySlice(
                    id: key,
                    name: EntryGlyph.name(for: key),
                    symbol: EntryGlyph.symbol(for: key),
                    amountCents: value,
                    share: Double(value) / Double(sum)
                )
            }
            .sorted { $0.amountCents > $1.amountCents }

        forecast = CashflowForecast.forecast(accounts: accounts, entries: entries, rules: rules, plans: plans)
        radar = SubscriptionRadar.detect(entries: entries)
    }
}
