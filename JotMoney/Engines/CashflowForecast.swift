import Foundation

struct ForecastPoint: Identifiable {
    let id = UUID()
    let date: Date
    let balanceCents: Int64
}

enum CashflowForecast {
    static func forecast(
        accounts: [Account],
        entries: [LedgerEntry],
        rules: [RecurringRule],
        plans: [InstallmentPlan],
        days: Int = 30,
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> [ForecastPoint] {
        let startBalance = BalanceEngine.spendableCash(accounts: accounts, entries: entries)
        let lookbackStart = calendar.date(byAdding: .day, value: -90, to: now) ?? now
        let recentSpend = entries
            .filter { $0.type == .expense && !$0.isArchived && $0.date >= lookbackStart && $0.date <= now }
            .reduce(Int64(0)) { $0 + $1.amountCents }
        let dailyVariable = (Double(recentSpend) / 90.0) * 1.1

        var points: [ForecastPoint] = []
        var running = Double(startBalance)

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)) else { break }
            running -= dailyVariable

            for rule in rules where rule.isActive {
                let delta = Double(rule.amountCents) * (rule.type == .income ? 1 : -1)
                if occurs(rule: rule, on: day, calendar: calendar) {
                    running += delta
                }
            }

            for plan in plans where !plan.isArchived {
                let dates = InstallmentEngine.schedule(plan: plan, calendar: calendar)
                for index in plan.generatedCount..<min(dates.count, plan.periodCount) where calendar.isDate(dates[index], inSameDayAs: day) {
                    running -= Double(InstallmentEngine.periodAmount(plan: plan, index: index))
                }
            }

            points.append(ForecastPoint(date: day, balanceCents: Int64(running.rounded())))
        }

        return points
    }

    private static func occurs(rule: RecurringRule, on day: Date, calendar: Calendar) -> Bool {
        let dayOfMonth = calendar.component(.day, from: day)
        let anchorDay = calendar.component(.day, from: rule.anchorDate)
        switch rule.cadence {
        case .monthly:
            let lastDay = calendar.range(of: .day, in: .month, for: day)?.count ?? 31
            return dayOfMonth == min(anchorDay, lastDay)
        case .weekly:
            let delta = calendar.dateComponents([.day], from: calendar.startOfDay(for: rule.anchorDate), to: calendar.startOfDay(for: day)).day ?? -1
            return delta >= 0 && delta % 7 == 0
        case .biweekly:
            let delta = calendar.dateComponents([.day], from: calendar.startOfDay(for: rule.anchorDate), to: calendar.startOfDay(for: day)).day ?? -1
            return delta >= 0 && delta % 14 == 0
        case .yearly:
            let anchorMonth = calendar.component(.month, from: rule.anchorDate)
            let currentMonth = calendar.component(.month, from: day)
            let lastDay = calendar.range(of: .day, in: .month, for: day)?.count ?? 31
            return anchorMonth == currentMonth && dayOfMonth == min(anchorDay, lastDay)
        }
    }
}
