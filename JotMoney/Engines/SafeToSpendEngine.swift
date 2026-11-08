import Foundation

struct SafeToSpendResult {
    let amountCents: Int64
    let availableCents: Int64
    let committedCents: Int64
    let daysLeft: Int
    let periodSpendCents: Int64
    let periodBudgetCents: Int64

    var progress: Double {
        guard periodBudgetCents > 0 else { return 0 }
        return min(1.0, Double(periodSpendCents) / Double(periodBudgetCents))
    }
}

enum SafeToSpendEngine {
    static func compute(
        accounts: [Account],
        entries: [LedgerEntry],
        budgets: [Budget],
        rules: [RecurringRule],
        plans: [InstallmentPlan],
        mode: SpendMode,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> SafeToSpendResult {
        let available = BalanceEngine.spendableCash(accounts: accounts, entries: entries)

        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<31
        let currentDay = calendar.component(.day, from: now)
        let daysLeft = max(1, range.count - currentDay + 1)
        let monthEnd = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: now),
            month: calendar.component(.month, from: now),
            day: range.count
        )) ?? now

        var committed: Int64 = 0

        for rule in rules where rule.isActive && rule.type == .expense {
            let occurrences = occurrencesOfRule(rule, from: now, to: monthEnd, calendar: calendar)
            committed += Int64(occurrences) * rule.amountCents
        }

        for plan in plans where !plan.isArchived {
            let dates = InstallmentEngine.schedule(plan: plan, calendar: calendar)
            guard plan.generatedCount < dates.count else { continue }
            for index in plan.generatedCount..<dates.count {
                let date = dates[index]
                if date >= calendar.startOfDay(for: now) && date <= monthEnd {
                    committed += InstallmentEngine.periodAmount(plan: plan, index: index)
                }
            }
        }

        let usable = max(0, available - committed)
        let daily = usable / Int64(daysLeft)
        let adjusted = Int64(Double(daily) * mode.allowanceFactor)

        let periodSpend = BalanceEngine.monthTotal(entries: entries, type: .expense, now: now, calendar: calendar)
        let periodBudget = budgets.reduce(Int64(0)) { $0 + $1.limitCents }

        return SafeToSpendResult(
            amountCents: max(0, min(adjusted, usable)),
            availableCents: available,
            committedCents: committed,
            daysLeft: daysLeft,
            periodSpendCents: periodSpend,
            periodBudgetCents: periodBudget > 0 ? periodBudget : max(periodSpend, 1)
        )
    }

    static func occurrencesOfRule(_ rule: RecurringRule, from start: Date, to end: Date, calendar: Calendar = .current) -> Int {
        var count = 0
        var cursor = calendar.startOfDay(for: rule.anchorDate)
        var guardCounter = 0
        while cursor <= end && guardCounter < 400 {
            guardCounter += 1
            if cursor >= calendar.startOfDay(for: start) { count += 1 }
            guard let next = calendar.date(byAdding: rule.cadence.component, value: rule.cadence.step, to: cursor) else { break }
            cursor = next
        }
        return count
    }
}
