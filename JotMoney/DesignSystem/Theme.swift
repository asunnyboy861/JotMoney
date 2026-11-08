import SwiftUI

enum Theme {
    static let mint = Color(hex: "00C48C")
    static let background = Color(hex: "0B0F0E")
    static let surface = Color(hex: "151A18")
    static let separator = Color(hex: "242B28")
    static let textPrimary = Color(hex: "F5F7F6")
    static let textSecondary = Color(hex: "9AA5A1")
    static let warning = Color(hex: "FFB020")
    static let danger = Color(hex: "FF5A5F")

    static let cardRadius: CGFloat = 20
    static let screenPadding: CGFloat = 20
}

extension Color {
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&value)
        let red: UInt64
        let green: UInt64
        let blue: UInt64
        switch sanitized.count {
        case 3:
            red = (value >> 8) * 17
            green = ((value >> 4) & 0xF) * 17
            blue = (value & 0xF) * 17
        default:
            red = value >> 16
            green = (value >> 8) & 0xFF
            blue = value & 0xFF
        }
        self.init(.sRGB,
                  red: Double(red) / 255.0,
                  green: Double(green) / 255.0,
                  blue: Double(blue) / 255.0,
                  opacity: 1.0)
    }
}

extension Int64 {
    var currencyText: String { MoneyFormatter.string(self) }
}

extension Date {
    var shortDayText: String {
        formatted(.dateTime.month(.abbreviated).day())
    }

    var timeText: String {
        formatted(.dateTime.hour().minute())
    }
}
