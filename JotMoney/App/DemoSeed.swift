#if DEBUG
import Foundation
import SwiftData

enum DemoSeed {
    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let accountDescriptor = FetchDescriptor<Account>()
        let existing = (try? context.fetch(accountDescriptor)) ?? []
        guard existing.isEmpty else { return }

        let checking = Account(name: "Checking", kind: .checking, openingBalanceCents: 240_000)
        checking.sortIndex = 0
        let credit = Account(name: "Credit Card", kind: .credit, openingBalanceCents: 18_000)
        credit.aprBps = 2299
        credit.sortIndex = 1
        context.insert(checking)
        context.insert(credit)

        let samples: [(String, Int64, String, Int)] = [
            ("Starbucks", 550, DefaultCategoryKey.dining, 0),
            ("Whole Foods", 8_420, DefaultCategoryKey.groceries, 0),
            ("Uber", 1_890, DefaultCategoryKey.transport, 1),
            ("Netflix", 1_599, DefaultCategoryKey.entertainment, 6),
            ("Amazon", 4_299, DefaultCategoryKey.shopping, 7),
            ("Chipotle", 1_240, DefaultCategoryKey.dining, 8),
            ("Shell", 5_610, DefaultCategoryKey.transport, 9),
            ("Netflix", 1_599, DefaultCategoryKey.entertainment, 36),
            ("Netflix", 1_599, DefaultCategoryKey.entertainment, 66)
        ]

        for sample in samples {
            let entry = LedgerEntry(
                amountCents: sample.1,
                type: .expense,
                merchantRaw: sample.0,
                merchantKey: sample.0.lowercased(),
                categoryKey: sample.2,
                accountID: sample.1 > 5_000 ? credit.id : checking.id,
                date: Calendar.current.date(byAdding: .day, value: -sample.3, to: Date()) ?? Date(),
                source: .quickEntry
            )
            context.insert(entry)
        }

        let salary = LedgerEntry(
            amountCents: 420_000,
            type: .income,
            merchantRaw: "Salary",
            merchantKey: "salary",
            categoryKey: DefaultCategoryKey.income,
            accountID: checking.id,
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            source: .manual
        )
        context.insert(salary)

        context.insert(Budget(categoryKey: DefaultCategoryKey.dining, limitCents: 30_000))
        context.insert(Budget(categoryKey: DefaultCategoryKey.groceries, limitCents: 60_000))

        let rent = RecurringRule(
            merchantRaw: "Rent",
            amountCents: 185_000,
            type: .expense,
            categoryKey: DefaultCategoryKey.bills,
            accountID: checking.id,
            cadence: .monthly,
            anchorDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
        )
        context.insert(rent)

        let memory = MerchantMemory(merchantKey: "starbucks", displayName: "Starbucks", defaultCategoryKey: DefaultCategoryKey.dining)
        memory.aliases = ["sbux"]
        context.insert(memory)

        EntryService.shared.save(context)
        AppPreferences.onboardingComplete = true
    }
}
#endif
