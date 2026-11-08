import Foundation
import SwiftData

@Model
final class Category {
    var key: String = ""
    var name: String = ""
    var symbolName: String = "square.grid.2x2.fill"
    var colorHex: String = "9AA5A1"
    var sortIndex: Int = 0
    var isBuiltIn: Bool = true

    init(key: String = "", name: String = "", symbolName: String = "square.grid.2x2.fill", colorHex: String = "9AA5A1", sortIndex: Int = 0) {
        self.key = key
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.sortIndex = sortIndex
    }
}
