import Foundation

enum AIError: LocalizedError {
    case notConfigured
    case requiresVision
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Add your own AI key in Settings → AI, or subscribe to Pro for the built-in AI."
        case .requiresVision:
            return "The selected model has vision turned off. Enable vision in Settings → AI to scan receipts."
        case .serviceUnavailable:
            return "The AI service is unavailable. Please try again."
        }
    }
}

enum AIRouter {
    static func parseEntry(_ raw: String, settings: BYOSettings) async -> ParsedEntry? {
        if let local = QuickEntryParser.parse(raw), local.confidence >= 0.85 {
            return local
        }
        if let ai = await AppleIntelligenceService.parseEntry(raw) {
            return ai
        }
        if settings.isConfigured {
            do {
                let client = OpenAICompatClient(settings: settings, apiKey: AISettingsStore.apiKey(for: settings.provider))
                let reply = try await client.complete(
                    system: "Convert a short expense note into JSON only: {\"amount\":number,\"merchant\":string,\"category\":\"groceries|dining|transport|shopping|bills|entertainment|health|income|other\",\"type\":\"expense|income\",\"confidence\":number}",
                    user: raw,
                    maxTokens: 600
                )
                if let parsed = decodeEntry(reply) { return parsed }
            } catch {
                print("AI parse failed: \(error.localizedDescription)")
            }
        }
        return QuickEntryParser.parse(raw)
    }

    static func scanReceipt(jpeg: Data, settings: BYOSettings, isPro: Bool) async throws -> ReceiptResult {
        let base64 = jpeg.base64EncodedString()

        if settings.supportsVision && settings.isConfigured {
            let client = OpenAICompatClient(settings: settings, apiKey: AISettingsStore.apiKey(for: settings.provider))
            let reply = try await client.completeWithImage(
                system: ReceiptParser.systemPrompt,
                user: "Extract this receipt into the schema.",
                imageJPEG: jpeg
            )
            if let result = ReceiptParser.decode(reply) { return result }
            throw AIRequestError(message: "Could not read this receipt. Try a sharper, straight-on photo.")
        }

        guard isPro else { throw AIError.notConfigured }

        let reply = try await GLMClient.shared.chatWithImage(
            base64JPEG: base64,
            systemPrompt: ReceiptParser.systemPrompt,
            userText: "Extract this receipt into the schema."
        )
        guard let result = ReceiptParser.decode(reply) else {
            throw AIRequestError(message: "Could not read this receipt. Try a sharper, straight-on photo.")
        }
        return result
    }

    static func coach(question: String, summary: String, settings: BYOSettings, isPro: Bool) async throws -> String {
        if let local = await AppleIntelligenceService.coachReply(question: question, ledgerSummary: summary) {
            return local
        }
        if settings.isConfigured {
            let client = OpenAICompatClient(settings: settings, apiKey: AISettingsStore.apiKey(for: settings.provider))
            return try await client.complete(
                system: "You are a concise, practical money coach. Use the ledger summary and USD amounts. Never give investment or tax advice. Keep answers under 120 words.",
                user: "Ledger summary:\n\(summary)\n\nQuestion: \(question)",
                maxTokens: 2000
            )
        }
        guard isPro else { throw AIError.notConfigured }
        return try await GLMClient.shared.chat(
            system: "You are a concise, practical money coach. Use the ledger summary and USD amounts. Never give investment or tax advice. Keep answers under 120 words.",
            user: "Ledger summary:\n\(summary)\n\nQuestion: \(question)",
            maxTokens: 4096,
            jsonMode: false
        )
    }

    private static func decodeEntry(_ raw: String) -> ParsedEntry? {
        guard let start = raw.firstIndex(of: "{"), let end = raw.lastIndex(of: "}") else { return nil }
        let json = String(raw[start...end])
        guard let data = json.data(using: .utf8) else { return nil }
        struct Payload: Decodable {
            let amount: Double
            let merchant: String
            let category: String?
            let type: String?
            let confidence: Double?
        }
        guard let payload = try? JSONDecoder().decode(Payload.self, from: data), payload.amount > 0 else { return nil }
        let key = payload.merchant.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return ParsedEntry(
            amountCents: Int64((payload.amount * 100).rounded()),
            merchantRaw: payload.merchant,
            merchantKey: key,
            categoryKey: payload.category ?? DefaultCategoryKey.other,
            accountID: nil,
            type: EntryType(rawValue: payload.type ?? "expense") ?? .expense,
            confidence: payload.confidence ?? 0.9,
            origin: .byoAI
        )
    }
}
