import Foundation

enum MoneyFormatter {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let compactFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter
    }()

    static func string(_ cents: Int64, currencyCode: String = "USD") -> String {
        let amount = NSDecimalNumber(value: cents).dividing(by: 100)
        currencyFormatter.currencyCode = currencyCode
        return currencyFormatter.string(from: amount) ?? "$0.00"
    }

    static func string(_ cents: Int64, showCents: Bool) -> String {
        let amount = NSDecimalNumber(value: cents).dividing(by: 100)
        if showCents {
            return currencyFormatter.string(from: amount) ?? "$0.00"
        }
        return compactFormatter.string(from: amount) ?? "$0"
    }

    static func signed(_ cents: Int64) -> String {
        let prefix = cents < 0 ? "−" : "+"
        return prefix + string(abs(cents))
    }

    static func decimalCents(_ text: String) -> Int64? {
        let cleaned = text
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        guard let value = Double(cleaned) else { return nil }
        return Int64((value * 100).rounded())
    }

    static func amountText(_ cents: Int64) -> String {
        let dollars = Double(cents) / 100
        if cents % 100 == 0 {
            return String(format: "%.0f", dollars)
        }
        return String(format: "%.2f", dollars)
    }
}
