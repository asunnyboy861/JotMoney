import Foundation

struct ReceiptResult {
    var merchant: String
    var totalCents: Int64
    var taxCents: Int64?
    var tipCents: Int64?
    var categoryKey: String
    var items: [ReceiptItem]
    var confidence: Double
}

struct ReceiptItem: Identifiable {
    let id = UUID()
    var name: String
    var priceCents: Int64
}

enum ReceiptParser {
    static let systemPrompt = """
    You extract structured data from receipt photos. Reply with strict JSON only, no markdown fences.
    Schema: {"merchant":string,"date":"YYYY-MM-DD"|null,"total":number,"tax":number|null,"tip":number|null,
    "items":[{"name":string,"price":number}],"suggested_category":"groceries|dining|transport|shopping|bills|entertainment|health|other","confidence":number}
    Amounts are plain decimal numbers in US dollars. Never include currency symbols.
    """

    static func decode(_ raw: String) -> ReceiptResult? {
        guard let jsonText = extractJSON(raw),
              let data = jsonText.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return nil
        }
        let total = Int64((payload.total * 100).rounded())
        guard total > 0 else { return nil }
        let items = (payload.items ?? []).map {
            ReceiptItem(name: $0.name, priceCents: Int64(($0.price * 100).rounded()))
        }
        return ReceiptResult(
            merchant: payload.merchant.isEmpty ? "Receipt" : payload.merchant,
            totalCents: total,
            taxCents: payload.tax.map { Int64(($0 * 100).rounded()) },
            tipCents: payload.tip.map { Int64(($0 * 100).rounded()) },
            categoryKey: normalizeCategory(payload.suggested_category),
            items: items,
            confidence: payload.confidence ?? 0.8
        )
    }

    private static func extractJSON(_ raw: String) -> String? {
        if let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") {
            return String(raw[start...end])
        }
        return nil
    }

    private static func normalizeCategory(_ value: String?) -> String {
        let key = (value ?? "").lowercased()
        let allowed = DefaultCategoryKey.all.map { $0.key }
        return allowed.contains(key) ? key : DefaultCategoryKey.other
    }

    private struct Payload: Decodable {
        let merchant: String
        let total: Double
        let tax: Double?
        let tip: Double?
        let items: [Item]?
        let suggested_category: String?
        let confidence: Double?

        struct Item: Decodable {
            let name: String
            let price: Double
        }
    }
}
