import Foundation

enum BalanceEngine {
    static func balanceCents(for account: Account, entries: [LedgerEntry]) -> Int64 {
        let accountEntries = entries.filter { $0.accountID == account.id && !$0.isArchived }
        let delta = accountEntries.reduce(Int64(0)) { $0 + $1.signedCents }
        if account.isLiability {
            return account.openingBalanceCents - delta
        }
        return account.openingBalanceCents + delta
    }

    static func netWorth(accounts: [Account], entries: [LedgerEntry]) -> Int64 {
        accounts
            .filter { !$0.isArchived }
            .reduce(Int64(0)) { partial, account in
                let balance = balanceCents(for: account, entries: entries)
                return partial + (account.isLiability ? -balance : balance)
            }
    }

    static func spendableCash(accounts: [Account], entries: [LedgerEntry]) -> Int64 {
        accounts
            .filter { !$0.isArchived && !$0.isLiability }
            .reduce(Int64(0)) { $0 + balanceCents(for: $1, entries: entries) }
    }

    static func monthTotal(entries: [LedgerEntry], type: EntryType, now: Date = Date(), calendar: Calendar = .current) -> Int64 {
        entries
            .filter { $0.type == type && calendar.isDate($0.date, equalTo: now, toGranularity: .month) && !$0.isArchived }
            .reduce(Int64(0)) { $0 + $1.amountCents }
    }

    static func categoryTotals(entries: [LedgerEntry], now: Date = Date(), calendar: Calendar = .current) -> [String: Int64] {
        var totals: [String: Int64] = [:]
        for entry in entries where entry.type == .expense && !entry.isArchived && calendar.isDate(entry.date, equalTo: now, toGranularity: .month) {
            totals[entry.categoryKey, default: 0] += entry.amountCents
        }
        return totals
    }

    static func dayTotal(entries: [LedgerEntry], on day: Date = Date(), calendar: Calendar = .current) -> Int64 {
        entries
            .filter { $0.type == .expense && !$0.isArchived && calendar.isDate($0.date, inSameDayAs: day) }
            .reduce(Int64(0)) { $0 + $1.amountCents }
    }

    static func entries(on day: Date, from entries: [LedgerEntry], calendar: Calendar = .current) -> [LedgerEntry] {
        entries
            .filter { !$0.isArchived && calendar.isDate($0.date, inSameDayAs: day) }
            .sorted { $0.date > $1.date }
    }
}
