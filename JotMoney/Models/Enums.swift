import Foundation

enum AccountKind: String, CaseIterable, Identifiable {
    case cash
    case checking
    case savings
    case credit
    case asset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "Cash"
        case .checking: return "Checking"
        case .savings: return "Savings"
        case .credit: return "Credit"
        case .asset: return "Asset"
        }
    }

    var symbolName: String {
        switch self {
        case .cash: return "banknote"
        case .checking: return "building.columns"
        case .savings: return "leaf"
        case .credit: return "creditcard"
        case .asset: return "chart.line.uptrend.xyaxis"
        }
    }

    var isLiability: Bool { self == .credit }
}

enum EntryType: String, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }
}

enum EntrySource: String {
    case manual
    case quickEntry
    case voice
    case ocr
    case rule
    case shared
    case imported

    var title: String {
        switch self {
        case .manual: return "Manual"
        case .quickEntry: return "Quick entry"
        case .voice: return "Voice"
        case .ocr: return "Receipt"
        case .rule: return "Recurring"
        case .shared: return "Shared"
        case .imported: return "Imported"
        }
    }
}

enum CadenceType: String, CaseIterable, Identifiable {
    case weekly
    case biweekly
    case monthly
    case yearly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .weekly: return .weekOfYear
        case .biweekly: return .weekOfYear
        case .monthly: return .month
        case .yearly: return .year
        }
    }

    var step: Int {
        switch self {
        case .weekly: return 1
        case .biweekly: return 2
        case .monthly: return 1
        case .yearly: return 1
        }
    }

    var approximateDays: Int {
        switch self {
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .yearly: return 365
        }
    }
}

enum SpendMode: String, CaseIterable, Identifiable {
    case conservative
    case standard
    case relaxed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .conservative: return "Conservative"
        case .standard: return "Standard"
        case .relaxed: return "Relaxed"
        }
    }

    var allowanceFactor: Double {
        switch self {
        case .conservative: return 0.8
        case .standard: return 1.0
        case .relaxed: return 1.2
        }
    }
}

enum ParseOrigin: String {
    case rule
    case dictionary
    case merchantMemory
    case appleAI
    case byoAI
    case glm
    case manual
}

enum LedgerError: LocalizedError {
    case planMismatch(total: Int64, product: Int64)

    var errorDescription: String? {
        switch self {
        case .planMismatch(let total, let product):
            return "Installment total \(MoneyFormatter.string(total)) does not match \(MoneyFormatter.string(product)) across all periods."
        }
    }
}

enum DefaultCategoryKey {
    static let groceries = "groceries"
    static let dining = "dining"
    static let transport = "transport"
    static let shopping = "shopping"
    static let bills = "bills"
    static let entertainment = "entertainment"
    static let health = "health"
    static let income = "income"
    static let other = "other"

    static let all: [(key: String, name: String, symbol: String)] = [
        (groceries, "Groceries", "cart.fill"),
        (dining, "Dining", "fork.knife"),
        (transport, "Transport", "car.fill"),
        (shopping, "Shopping", "bag.fill"),
        (bills, "Bills", "doc.text.fill"),
        (entertainment, "Entertainment", "play.tv.fill"),
        (health, "Health", "cross.case.fill"),
        (income, "Income", "arrow.down.circle.fill"),
        (other, "Other", "square.grid.2x2.fill")
    ]
}
