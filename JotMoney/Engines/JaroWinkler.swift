import Foundation

enum JaroWinkler {
    static func similarity(_ first: String, _ second: String) -> Double {
        let a = Array(first.lowercased())
        let b = Array(second.lowercased())
        if a.isEmpty && b.isEmpty { return 1.0 }
        if a.isEmpty || b.isEmpty { return 0.0 }
        if a == b { return 1.0 }

        let matchWindow = max(a.count, b.count) / 2 - 1
        var aMatched = Array(repeating: false, count: a.count)
        var bMatched = Array(repeating: false, count: b.count)
        var matches = 0

        for i in 0..<a.count {
            let start = max(0, i - matchWindow)
            let end = min(i + matchWindow, b.count - 1)
            guard start <= end else { continue }
            for j in start...end where !bMatched[j] && a[i] == b[j] {
                aMatched[i] = true
                bMatched[j] = true
                matches += 1
                break
            }
        }

        guard matches > 0 else { return 0.0 }

        var transpositions = 0
        var k = 0
        for i in 0..<a.count where aMatched[i] {
            while !bMatched[k] { k += 1 }
            if a[i] != b[k] { transpositions += 1 }
            k += 1
        }

        let matchCount = Double(matches)
        let jaro = (
            matchCount / Double(a.count)
            + matchCount / Double(b.count)
            + (matchCount - Double(transpositions) / 2.0) / matchCount
        ) / 3.0

        var prefix = 0
        for i in 0..<min(4, min(a.count, b.count)) {
            if a[i] == b[i] { prefix += 1 } else { break }
        }

        let winkler = jaro + Double(prefix) * 0.1 * (1.0 - jaro)
        return min(1.0, winkler)
    }
}
