import Foundation
import SwiftData

@Model
final class MerchantMemory {
    var merchantKey: String = ""
    var displayName: String = ""
    var aliasesCSV: String = ""
    var defaultCategoryKey: String = DefaultCategoryKey.other
    var defaultAccountID: UUID?
    var hitCount: Int = 0
    var updatedAt: Date = Date()

    init(merchantKey: String = "", displayName: String = "", defaultCategoryKey: String = DefaultCategoryKey.other) {
        self.merchantKey = merchantKey
        self.displayName = displayName
        self.defaultCategoryKey = defaultCategoryKey
    }

    var aliases: [String] {
        get { aliasesCSV.isEmpty ? [] : aliasesCSV.components(separatedBy: ",") }
        set { aliasesCSV = newValue.filter { !$0.isEmpty }.joined(separator: ",") }
    }

    func addAlias(_ value: String) {
        let normalized = value.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty, normalized != merchantKey else { return }
        var current = aliases
        if !current.contains(normalized) {
            current.append(normalized)
            aliases = current
        }
    }
}
