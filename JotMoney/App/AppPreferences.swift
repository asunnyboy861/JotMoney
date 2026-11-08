import Foundation

enum AppGroupSnapshot {
    static let suiteName = "group.com.zzoutuo.JotMoney"
    private static let safeToSpendKey = "safeToSpendCents"

    static func writeSafeToSpend(_ cents: Int64) {
        UserDefaults(suiteName: suiteName)?.set(cents, forKey: safeToSpendKey)
    }

    static func readSafeToSpend() -> Int64 {
        UserDefaults(suiteName: suiteName)?.object(forKey: safeToSpendKey) as? Int64 ?? 0
    }
}

enum AppPreferences {
    private static let defaults = UserDefaults.standard

    static var onboardingComplete: Bool {
        get { defaults.bool(forKey: "onboardingComplete") }
        set { defaults.set(newValue, forKey: "onboardingComplete") }
    }

    static var spendMode: SpendMode {
        get { SpendMode(rawValue: defaults.string(forKey: "spendMode") ?? "") ?? .standard }
        set { defaults.set(newValue.rawValue, forKey: "spendMode") }
    }

    static var iCloudSyncEnabled: Bool {
        get { defaults.bool(forKey: "iCloudSyncEnabled") }
        set { defaults.set(newValue, forKey: "iCloudSyncEnabled") }
    }

    static var lastRecurringRun: Date {
        get { defaults.object(forKey: "lastRecurringRun") as? Date ?? .distantPast }
        set { defaults.set(newValue, forKey: "lastRecurringRun") }
    }
}
