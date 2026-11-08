import Foundation

struct AIRequestError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

struct OpenAICompatClient {
    let settings: BYOSettings
    let apiKey: String

    func complete(system: String, user: String, maxTokens: Int = 700) async throws -> String {
        try await send(messages: [
            MessagePayload(role: "system", text: system, imageBase64: nil),
            MessagePayload(role: "user", text: user, imageBase64: nil)
        ], maxTokens: maxTokens)
    }

    func completeWithImage(system: String, user: String, imageJPEG: Data, maxTokens: Int = AISettingsStore.visionTokenLimit) async throws -> String {
        try await send(messages: [
            MessagePayload(role: "system", text: system, imageBase64: nil),
            MessagePayload(role: "user", text: user, imageBase64: imageJPEG.base64EncodedString())
        ], maxTokens: maxTokens)
    }

    private func send(messages: [MessagePayload], maxTokens: Int) async throws -> String {
        guard let endpoint = settings.chatEndpoint else {
            throw AIRequestError(message: "Add a valid endpoint URL in Settings → AI.")
        }
        guard !apiKey.isEmpty else {
            throw AIRequestError(message: "Add your API key in Settings → AI.")
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let body = RequestBody(
            model: settings.model,
            messages: messages.map { $0.encoded() },
            temperature: 0.2,
            max_tokens: maxTokens
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AIRequestError(message: "The AI service did not respond.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AIRequestError(message: "AI request failed (\(http.statusCode)). \(Self.shortError(body))")
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let content = decoded.choices.first?.message.content, !content.isEmpty else {
            throw AIRequestError(message: "The AI service returned an empty response.")
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func shortError(_ body: String) -> String {
        guard let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return String(body.prefix(160))
        }
        if let error = json["error"] as? [String: Any], let message = error["message"] as? String {
            return message
        }
        if let message = json["message"] as? String { return message }
        return String(body.prefix(160))
    }

    private struct RequestBody: Encodable {
        let model: String
        let messages: [Message]
        let temperature: Double
        let max_tokens: Int
    }

    private enum Message: Encodable {
        case plain(role: String, text: String)
        case vision(role: String, text: String, base64: String)

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .plain(let role, let text):
                try container.encode(role, forKey: .role)
                try container.encode(text, forKey: .content)
            case .vision(let role, let text, let base64):
                try container.encode(role, forKey: .role)
                var list = container.nestedUnkeyedContainer(forKey: .content)
                try list.encode(Part(type: "text", text: text))
                try list.encode(PartImage(type: "image_url", image_url: ImageURL(url: "data:image/jpeg;base64,\(base64)")))
            }
        }

        enum CodingKeys: String, CodingKey {
            case role
            case content
        }
    }

    private struct Part: Encodable {
        let type: String
        let text: String
    }

    private struct PartImage: Encodable {
        let type: String
        let image_url: ImageURL
    }

    private struct ImageURL: Encodable {
        let url: String
    }

    private struct MessagePayload {
        let role: String
        let text: String
        let imageBase64: String?

        func encoded() -> Message {
            if let imageBase64 {
                return .vision(role: role, text: text, base64: imageBase64)
            }
            return .plain(role: role, text: text)
        }
    }

    private struct ResponseBody: Decodable {
        struct Choice: Decodable {
            struct MessageBody: Decodable {
                let content: String?
            }
            let message: MessageBody
        }
        let choices: [Choice]
    }
}
