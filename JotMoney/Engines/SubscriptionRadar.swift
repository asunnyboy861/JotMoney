import Foundation

struct SubscriptionSuspicion: Identifiable {
    let id = UUID()
    let merchantKey: String
    let displayName: String
    let amountCents: Int64
    let occurrences: Int
    let intervalDays: Int
}

enum SubscriptionRadar {
    static func detect(entries: [LedgerEntry], calendar: Calendar = .current) -> [SubscriptionSuspicion] {
        let expenses = entries.filter { $0.type == .expense && !$0.isArchived && $0.source != .rule }
        let grouped = Dictionary(grouping: expenses) { $0.merchantKey }
        var results: [SubscriptionSuspicion] = []

        for (key, group) in grouped where group.count >= 3 {
            let sorted = group.sorted { $0.date < $1.date }
            guard let reference = sorted.last else { continue }
            let tolerance = Int(Double(reference.amountCents) * 0.05) + 1
            let similar = sorted.filter { abs($0.amountCents - reference.amountCents) <= tolerance }
            guard similar.count >= 3 else { continue }

            var intervals: [Int] = []
            for index in 1..<similar.count {
                let gap = calendar.dateComponents([.day], from: similar[index - 1].date, to: similar[index].date).day ?? 0
                if gap > 0 { intervals.append(gap) }
            }
            guard intervals.count >= 2 else { continue }

            let stable = stableInterval(for: intervals)
            guard let detected = stable else { continue }

            results.append(SubscriptionSuspicion(
                merchantKey: key,
                displayName: similar.last?.displayMerchant ?? key,
                amountCents: reference.amountCents,
                occurrences: similar.count,
                intervalDays: detected
            ))
        }

        return results.sorted { $0.amountCents > $1.amountCents }
    }

    private static func stableInterval(for intervals: [Int]) -> Int? {
        let targets = [7, 14, 30, 31, 365]
        for target in targets {
            if intervals.allSatisfy({ abs($0 - target) <= 2 }) {
                return target
            }
        }
        return nil
    }
}
