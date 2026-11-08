import Foundation

struct DuplicateHit {
    let existing: LedgerEntry
    let similarity: Double
    let isHighConfidence: Bool
}

enum DuplicateDetector {
    static func check(
        amountCents: Int64,
        merchantKey: String,
        date: Date,
        type: EntryType,
        in entries: [LedgerEntry],
        excluding: UUID? = nil
    ) -> DuplicateHit? {
        var best: DuplicateHit?
        let calendar = Calendar.current
        for entry in entries {
            guard !entry.isArchived else { continue }
            if let excluding, entry.id == excluding { continue }
            guard entry.type == type else { continue }
            guard abs(entry.amountCents - amountCents) <= 1 else { continue }
            let dayGap = abs(calendar.dateComponents([.day], from: entry.date, to: date).day ?? 99)
            guard dayGap <= 3 else { continue }
            let similarity = JaroWinkler.similarity(entry.merchantKey, merchantKey)
            guard similarity >= 0.85 else { continue }
            let highConfidence = dayGap == 0 && abs(entry.amountCents - amountCents) == 0 && similarity >= 0.95
            let hit = DuplicateHit(existing: entry, similarity: similarity, isHighConfidence: highConfidence)
            if similarity > (best?.similarity ?? 0) {
                best = hit
            }
        }
        return best
    }
}
