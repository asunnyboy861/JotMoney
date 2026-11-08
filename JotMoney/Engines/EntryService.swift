import Foundation
import SwiftData

@MainActor
final class EntryService {
    static let shared = EntryService()

    private init() {}

    @discardableResult
    func commit(
        parsed: ParsedEntry,
        accountID: UUID,
        categoryKey: String,
        note: String = "",
        date: Date = Date(),
        source: EntrySource = .quickEntry,
        receiptPath: String = "",
        context: ModelContext
    ) -> LedgerEntry {
        let entry = LedgerEntry(
            amountCents: parsed.amountCents,
            type: parsed.type,
            merchantRaw: parsed.merchantRaw,
            merchantKey: parsed.merchantKey,
            categoryKey: categoryKey,
            accountID: accountID,
            date: date,
            source: source
        )
        entry.note = note
        entry.receiptImagePath = receiptPath
        context.insert(entry)
        learnMerchant(
            merchantKey: parsed.merchantKey,
            displayName: parsed.merchantRaw,
            categoryKey: categoryKey,
            accountID: accountID,
            context: context
        )
        log(action: "entry.created", entityID: entry.id.uuidString, detail: "\(parsed.merchantRaw) \(MoneyFormatter.string(parsed.amountCents))", context: context)
        save(context)
        return entry
    }

    func upsert(_ entry: LedgerEntry, context: ModelContext) {
        let key = entry.idempotencyKey
        let descriptor = FetchDescriptor<LedgerEntry>(predicate: #Predicate { $0.idempotencyKey == key })
        if let existing = try? context.fetch(descriptor).first, existing.id != entry.id {
            existing.amountCents = entry.amountCents
            existing.date = entry.date
            existing.categoryKey = entry.categoryKey
            existing.note = entry.note
            existing.isArchived = entry.isArchived
        } else {
            context.insert(entry)
        }
        save(context)
    }

    func merge(_ entry: LedgerEntry, into origin: LedgerEntry, context: ModelContext) {
        entry.pendingOf = origin.id
        entry.isArchived = true
        log(action: "entry.merged", entityID: entry.id.uuidString, detail: "merged into \(origin.id.uuidString)", context: context)
        save(context)
    }

    func undoMerge(_ entry: LedgerEntry, context: ModelContext) {
        entry.pendingOf = nil
        entry.isArchived = false
        log(action: "entry.mergeUndone", entityID: entry.id.uuidString, detail: "restored", context: context)
        save(context)
    }

    func archive(_ entry: LedgerEntry, context: ModelContext) {
        entry.isArchived = true
        log(action: "entry.archived", entityID: entry.id.uuidString, detail: entry.displayMerchant, context: context)
        save(context)
    }

    func learnMerchant(
        merchantKey: String,
        displayName: String,
        categoryKey: String,
        accountID: UUID?,
        context: ModelContext
    ) {
        guard !merchantKey.isEmpty else { return }
        let key = merchantKey
        let descriptor = FetchDescriptor<MerchantMemory>(predicate: #Predicate { $0.merchantKey == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.defaultCategoryKey = categoryKey
            if let accountID { existing.defaultAccountID = accountID }
            existing.hitCount += 1
            existing.updatedAt = Date()
            if !displayName.isEmpty { existing.addAlias(displayName) }
        } else {
            let memory = MerchantMemory(merchantKey: key, displayName: displayName, defaultCategoryKey: categoryKey)
            memory.defaultAccountID = accountID
            memory.hitCount = 1
            context.insert(memory)
        }
    }

    func materializeInstallments(context: ModelContext, now: Date = Date()) {
        let descriptor = FetchDescriptor<InstallmentPlan>(predicate: #Predicate { $0.isArchived == false })
        guard let plans = try? context.fetch(descriptor) else { return }
        for plan in plans {
            let due = InstallmentEngine.dueIndices(plan: plan, now: now)
            guard !due.isEmpty else { continue }
            for index in due {
                let entry = LedgerEntry(
                    amountCents: InstallmentEngine.periodAmount(plan: plan, index: index),
                    type: .expense,
                    merchantRaw: plan.merchantRaw,
                    merchantKey: plan.merchantKey,
                    categoryKey: plan.categoryKey,
                    accountID: plan.accountID,
                    date: InstallmentEngine.schedule(plan: plan)[index],
                    source: .rule
                )
                entry.installmentPlanID = plan.id
                entry.ruleID = plan.id
                context.insert(entry)
                plan.generatedCount = index + 1
            }
        }
        save(context)
    }

    func materializeRecurring(context: ModelContext, now: Date = Date()) {
        let descriptor = FetchDescriptor<RecurringRule>(predicate: #Predicate { $0.isActive == true })
        guard let rules = try? context.fetch(descriptor) else { return }
        let calendar = Calendar.current
        for rule in rules {
            var cursor = calendar.startOfDay(for: rule.lastGeneratedDate ?? calendar.date(byAdding: .day, value: -1, to: rule.anchorDate) ?? rule.anchorDate)
            guard let next = calendar.date(byAdding: rule.cadence.component, value: rule.cadence.step, to: cursor) else { continue }
            cursor = next
            var counter = 0
            while cursor <= now && counter < 24 {
                counter += 1
                let entry = LedgerEntry(
                    amountCents: rule.amountCents,
                    type: rule.type,
                    merchantRaw: rule.merchantRaw,
                    merchantKey: rule.merchantKey,
                    categoryKey: rule.categoryKey,
                    accountID: rule.accountID,
                    date: cursor,
                    source: .rule
                )
                entry.ruleID = rule.id
                context.insert(entry)
                rule.lastGeneratedDate = cursor
                guard let advanced = calendar.date(byAdding: rule.cadence.component, value: rule.cadence.step, to: cursor) else { break }
                cursor = advanced
            }
        }
        AppPreferences.lastRecurringRun = now
        save(context)
    }

    func log(action: String, entityID: String, detail: String, context: ModelContext) {
        context.insert(AuditLogEntry(action: action, entityID: entityID, detail: detail))
    }

    func save(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("JotMoney save failed: \(error.localizedDescription)")
        }
    }

    func seedIfNeeded(context: ModelContext) {
        let categoryDescriptor = FetchDescriptor<Category>()
        let existingCategories = (try? context.fetch(categoryDescriptor)) ?? []
        if existingCategories.isEmpty {
            for (index, item) in DefaultCategoryKey.all.enumerated() {
                let category = Category(key: item.key, name: item.name, symbolName: item.symbol, sortIndex: index)
                context.insert(category)
            }
        }
        save(context)
    }
}
