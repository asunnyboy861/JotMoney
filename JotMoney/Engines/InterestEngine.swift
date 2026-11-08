import Foundation

enum InterestEngine {
    static func accrue(aprBps: Int, dailyBalances: [(day: Date, cents: Int64)]) -> Int64 {
        guard aprBps > 0, !dailyBalances.isEmpty else { return 0 }
        let dailyRate = Double(aprBps) / 10_000.0 / 365.0
        let total = dailyBalances.reduce(0.0) { partial, item in
            partial + Double(item.cents) * dailyRate
        }
        return Int64(total.rounded())
    }

    static func dailyBalances(
        openingCents: Int64,
        entries: [LedgerEntry],
        from start: Date,
        to end: Date,
        calendar: Calendar = .current
    ) -> [(day: Date, cents: Int64)] {
        var result: [(day: Date, cents: Int64)] = []
        var day = calendar.startOfDay(for: start)
        let lastDay = calendar.startOfDay(for: end)
        var running = openingCents

        while day <= lastDay {
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
            running += dayEntries.reduce(Int64(0)) { $0 + $1.signedCents }
            result.append((day: day, cents: running))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return result
    }

    static func currentMonthAccrual(
        account: Account,
        entries: [LedgerEntry],
        now: Date = Date(),
        calendar: Calendar = .current
    ) -> Int64 {
        guard account.aprBps > 0, !account.isLiability else { return 0 }
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let balances = dailyBalances(openingCents: account.openingBalanceCents, entries: entries, from: start, to: now, calendar: calendar)
        return accrue(aprBps: account.aprBps, dailyBalances: balances)
    }
}
