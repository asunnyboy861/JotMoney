import Foundation
import SwiftData
import AppIntents

struct LogEntryIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a transaction"
    static var description = IntentDescription("Log an expense or income in JotMoney with a short phrase.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Entry", requestValueDialog: "What did you spend?")
    var entry: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let parsed = QuickEntryParser.parse(entry) else {
            return .result(dialog: "I could not find an amount in that. Try “coffee five fifty”.")
        }
        let container = Persistence.makeContainer()
        let context = container.mainContext
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortIndex)])
        let accounts = (try? context.fetch(descriptor)) ?? []
        guard let account = accounts.first(where: { !$0.isArchived }) else {
            return .result(dialog: "Open JotMoney and create an account first.")
        }
        EntryService.shared.commit(
            parsed: parsed,
            accountID: account.id,
            categoryKey: parsed.categoryKey,
            source: .quickEntry,
            context: context
        )
        let formatted = MoneyFormatter.string(parsed.amountCents)
        return .result(dialog: "Logged \(formatted) at \(parsed.merchantRaw).")
    }
}

struct JotMoneyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogEntryIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Jot money in \(.applicationName)"
            ],
            shortTitle: "Log transaction",
            systemImageName: "bolt.fill"
        )
    }
}
