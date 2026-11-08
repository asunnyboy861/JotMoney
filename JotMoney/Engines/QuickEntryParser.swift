import Foundation

struct ParsedEntry: Equatable {
    var amountCents: Int64
    var merchantRaw: String
    var merchantKey: String
    var categoryKey: String
    var accountID: UUID?
    var type: EntryType
    var confidence: Double
    var origin: ParseOrigin

    var needsConfirmation: Bool { confidence < 0.85 }
}

enum QuickEntryParser {
    static func parse(_ raw: String, memories: [MerchantMemory] = []) -> ParsedEntry? {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        guard let amountMatch = text.firstMatch(of: /\$?\s*(\d+(?:[.,]\d{1,2})?)/) else { return nil }
        guard let amountCents = MoneyFormatter.decimalCents(String(amountMatch.1)), amountCents > 0 else { return nil }

        var remainder = text
        if let range = remainder.range(of: String(amountMatch.0)) {
            remainder.removeSubrange(range)
        }

        let lowercased = remainder.lowercased()
        let incomeWords = ["salary", "paycheck", "payroll", "refund", "reimburse", "cashback", "received", "got paid", "income", "deposit"]
        let type: EntryType = incomeWords.contains(where: { lowercased.contains($0) }) ? .income : .expense

        var merchantText = cleanupMerchant(remainder)
        if merchantText.isEmpty { merchantText = type == .income ? "Income" : "Unknown" }

        let merchantKey = LedgerEntry.normalizeMerchant(merchantText)

        if let memory = bestMemory(for: merchantKey, in: memories) {
            return ParsedEntry(
                amountCents: amountCents,
                merchantRaw: memory.displayName,
                merchantKey: memory.merchantKey,
                categoryKey: memory.defaultCategoryKey,
                accountID: memory.defaultAccountID,
                type: type,
                confidence: 0.97,
                origin: .merchantMemory
            )
        }

        if let profile = MerchantDictionary.match(merchantKey) {
            return ParsedEntry(
                amountCents: amountCents,
                merchantRaw: profile.displayName,
                merchantKey: profile.displayName.lowercased(),
                categoryKey: type == .income ? DefaultCategoryKey.income : profile.categoryKey,
                accountID: nil,
                type: type,
                confidence: 0.95,
                origin: .dictionary
            )
        }

        return ParsedEntry(
            amountCents: amountCents,
            merchantRaw: merchantText,
            merchantKey: merchantKey,
            categoryKey: type == .income ? DefaultCategoryKey.income : DefaultCategoryKey.other,
            accountID: nil,
            type: type,
            confidence: 0.7,
            origin: .dictionary
        )
    }

    static func cleanupMerchant(_ value: String) -> String {
        var result = value
            .replacingOccurrences(of: "$", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let leadingWords = ["paid", "spent", "bought", "for", "to", "at", "on", "from", "-", ":"]
        var changed = true
        while changed {
            changed = false
            for word in leadingWords {
                let lowered = result.lowercased()
                if lowered.hasPrefix(word + " ") {
                    result = String(result.dropFirst(word.count + 1))
                    changed = true
                }
            }
        }

        let trailingWords = ["paid", "spent", "for"]
        for word in trailingWords where result.lowercased().hasSuffix(" " + word) {
            result = String(result.dropLast(word.count + 1))
        }

        return result
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "^\\W+", with: "", options: .regularExpression)
    }

    private static func bestMemory(for key: String, in memories: [MerchantMemory]) -> MerchantMemory? {
        guard !key.isEmpty else { return nil }
        if let exact = memories.first(where: { $0.merchantKey == key || $0.aliases.contains(key) }) {
            return exact
        }
        var best: MerchantMemory?
        var bestScore = 0.0
        for memory in memories {
            let score = JaroWinkler.similarity(memory.merchantKey, key)
            if score >= 0.92 && score > bestScore {
                bestScore = score
                best = memory
            }
        }
        return best
    }
}
