import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

enum AppleIntelligenceService {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability {
                return true
            }
        }
        #endif
        return false
    }

    static func parseEntry(_ raw: String) async -> ParsedEntry? {
        guard isAvailable else { return nil }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let instructions = """
            You convert a short expense note into JSON. Reply with JSON only.
            Schema: {"amount":number,"merchant":string,"category":"groceries|dining|transport|shopping|bills|entertainment|health|income|other","type":"expense|income","confidence":number}
            """
            let session = LanguageModelSession(instructions: instructions)
            guard let response = try? await session.respond(to: raw) else { return nil }
            return decode(response.content)
        }
        #endif
        return nil
    }

    static func coachReply(question: String, ledgerSummary: String) async -> String? {
        guard isAvailable else { return nil }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let instructions = """
            You are a concise, practical money coach. Use the supplied ledger summary and USD amounts.
            Never give investment or tax advice. Keep the answer under 120 words.
            """
            let session = LanguageModelSession(instructions: instructions)
            let prompt = "Ledger summary:\n\(ledgerSummary)\n\nQuestion: \(question)"
            guard let response = try? await session.respond(to: prompt) else { return nil }
            return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #endif
        return nil
    }

    private static func decode(_ raw: String) -> ParsedEntry? {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") else { return nil }
        let json = String(raw[start...end])
        guard let data = json.data(using: .utf8),
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              payload.amount > 0 else { return nil }
        let cents = Int64((payload.amount * 100).rounded())
        let key = payload.merchant.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let type = EntryType(rawValue: payload.type ?? "expense") ?? .expense
        return ParsedEntry(
            amountCents: cents,
            merchantRaw: payload.merchant,
            merchantKey: key,
            categoryKey: payload.category ?? DefaultCategoryKey.other,
            accountID: nil,
            type: type,
            confidence: payload.confidence ?? 0.9,
            origin: .appleAI
        )
    }

    private struct Payload: Decodable {
        let amount: Double
        let merchant: String
        let category: String?
        let type: String?
        let confidence: Double?
    }
}
