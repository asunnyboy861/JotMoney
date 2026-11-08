import Foundation
import StoreKit

enum GLMError: LocalizedError {
    case notConfigured
    case rateLimited
    case badResponse
    case emptyContent
    case receiptRejected

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Cloud AI is unavailable. Add your own API key in Settings → AI, or subscribe to Pro."
        case .rateLimited:
            return "Too many cloud requests right now. Please try again later."
        case .badResponse:
            return "The cloud service did not respond. Please try again."
        case .emptyContent:
            return "The cloud returned no result. Please try again."
        case .receiptRejected:
            return "Cloud AI needs an active Pro subscription. Restore your purchase or subscribe to continue."
        }
    }
}

final class GLMClient {
    static let shared = GLMClient()

    private let proxyURL = URL(string: "https://cramjam-api.calcs.top")!
    private let proxyFallbackURL = URL(string: "https://cramjam-proxy.iocompile67692.workers.dev")!
    private let model = "glm-5.3-flash"
    private let appId = "jotmoney"
    private let keychainService = "com.zzoutuo.JotMoney.glm"

    private var devKey: String? {
        guard let url = Bundle.main.url(forResource: "GLMProxySecret", withExtension: "txt"),
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private var userId: String {
        if let existing = KeychainHelper.readString(service: keychainService, account: "proxy_user_id") {
            return existing
        }
        let created = UUID().uuidString
        KeychainHelper.saveString(created, service: keychainService, account: "proxy_user_id")
        return created
    }

    var isConfigured: Bool { devKey != nil }

    private func currentEntitlementJWS() async -> String? {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil,
                  transaction.productType == .autoRenewable else { continue }
            let jws = result.jwsRepresentation
            if !jws.isEmpty { return jws }
        }
        return nil
    }

    func chat(system: String, user: String, maxTokens: Int = 4096, jsonMode: Bool = true) async throws -> String {
        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": user]
        ]
        return try await send(messages: messages, maxTokens: maxTokens, jsonMode: jsonMode)
    }

    func chatWithImage(base64JPEG: String, systemPrompt: String, userText: String, maxTokens: Int = 8192) async throws -> String {
        let content: [[String: Any]] = [
            ["type": "text", "text": systemPrompt + (userText.isEmpty ? "" : "\n\(userText)")],
            ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64JPEG)"]]
        ]
        return try await send(messages: [["role": "user", "content": content]], maxTokens: maxTokens, jsonMode: true)
    }

    private func send(messages: [[String: Any]], maxTokens: Int, jsonMode: Bool) async throws -> String {
        var payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "thinking": ["level": "low"],
            "max_tokens": maxTokens
        ]
        if jsonMode {
            payload["response_format"] = ["type": "json_object"]
        }

        var body: [String: Any] = [
            "appId": appId,
            "userId": userId,
            "payload": payload
        ]

        if let jws = await currentEntitlementJWS() {
            body["appTransaction"] = jws
        } else if let devKey {
            body["devKey"] = devKey
        } else {
            throw GLMError.notConfigured
        }

        do {
            return try await post(url: proxyURL, body: body)
        } catch GLMError.badResponse {
            return try await post(url: proxyFallbackURL, body: body)
        } catch GLMError.emptyContent {
            return try await post(url: proxyFallbackURL, body: body)
        }
    }

    private func post(url: URL, body: [String: Any]) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GLMError.badResponse }
        switch http.statusCode {
        case 200:
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let message = choices.first?["message"] as? [String: Any],
                  let content = message["content"] as? String, !content.isEmpty else {
                throw GLMError.emptyContent
            }
            return content
        case 401:
            throw GLMError.receiptRejected
        case 429:
            throw GLMError.rateLimited
        default:
            throw GLMError.badResponse
        }
    }
}
