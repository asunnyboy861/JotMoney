import SwiftUI

enum PolicyLinks {
    static let landing = URL(string: "https://asunnyboy861.github.io/JotMoney/")!
    static let support = URL(string: "https://asunnyboy861.github.io/JotMoney/support.html")!
    static let privacy = URL(string: "https://asunnyboy861.github.io/JotMoney/privacy.html")!
    static let terms = URL(string: "https://asunnyboy861.github.io/JotMoney/terms.html")!
}

enum AppVersionInfo {
    static var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    static var display: String {
        "Version \(version) (\(build))"
    }
}
