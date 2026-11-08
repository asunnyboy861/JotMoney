import Foundation
import SwiftUI

enum KeychainHelper {
    static func saveString(_ value: String, service: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func readString(service: String, account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum AIProvider: String, CaseIterable, Identifiable {
    case glm
    case openAI
    case gemini
    case claude
    case deepSeek
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .glm: return "GLM (Z.ai)"
        case .openAI: return "OpenAI"
        case .gemini: return "Google Gemini"
        case .claude: return "Anthropic Claude"
        case .deepSeek: return "DeepSeek"
        case .custom: return "Custom endpoint"
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .glm: return "https://api.z.ai/api/paas/v4"
        case .openAI: return "https://api.openai.com/v1"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/openai"
        case .claude: return "https://api.anthropic.com/v1"
        case .deepSeek: return "https://api.deepseek.com/v1"
        case .custom: return ""
        }
    }

    var defaultModel: String {
        switch self {
        case .glm: return "glm-4.6v-flash"
        case .openAI: return "gpt-4o-mini"
        case .gemini: return "gemini-2.0-flash"
        case .claude: return "claude-3-5-sonnet-latest"
        case .deepSeek: return "deepseek-chat"
        case .custom: return ""
        }
    }

    var supportsVisionByDefault: Bool {
        switch self {
        case .deepSeek: return false
        case .custom: return true
        default: return true
        }
    }
}

struct BYOSettings {
    var provider: AIProvider
    var baseURL: String
    var model: String
    var supportsVision: Bool

    var isConfigured: Bool {
        !baseURL.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.trimmingCharacters(in: .whitespaces).isEmpty
            && !AISettingsStore.apiKey(for: provider).isEmpty
    }

    var chatEndpoint: URL? {
        let trimmed = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasSuffix("/chat/completions") {
            return URL(string: trimmed)
        }
        return URL(string: trimmed + "/chat/completions")
    }
}

enum AISettingsStore {
    private static let defaults = UserDefaults.standard
    private static let keychainService = "com.zzoutuo.JotMoney.ai"
    private static let providerKey = "ai.provider"
    private static let baseURLKey = "ai.baseURL"
    private static let modelKey = "ai.model"
    private static let visionKey = "ai.supportsVision"
    static let visionTokenLimit = 8192

    static func apiKey(for provider: AIProvider) -> String {
        KeychainHelper.readString(service: keychainService, account: provider.rawValue) ?? ""
    }

    static func setAPIKey(_ value: String, for provider: AIProvider) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainHelper.delete(service: keychainService, account: provider.rawValue)
        } else {
            KeychainHelper.saveString(trimmed, service: keychainService, account: provider.rawValue)
        }
    }

    static func load() -> BYOSettings {
        let rawProvider = defaults.string(forKey: providerKey) ?? ""
        let provider = AIProvider(rawValue: rawProvider) ?? .glm
        let storedBaseURL = defaults.string(forKey: baseURLKey) ?? provider.defaultBaseURL
        let storedModel = defaults.string(forKey: modelKey) ?? provider.defaultModel
        let vision = defaults.object(forKey: visionKey) as? Bool ?? provider.supportsVisionByDefault
        return BYOSettings(provider: provider, baseURL: storedBaseURL, model: storedModel, supportsVision: vision)
    }

    static func save(_ settings: BYOSettings) {
        defaults.set(settings.provider.rawValue, forKey: providerKey)
        defaults.set(settings.baseURL, forKey: baseURLKey)
        defaults.set(settings.model, forKey: modelKey)
        defaults.set(settings.supportsVision, forKey: visionKey)
    }

    static func reset() {
        defaults.removeObject(forKey: providerKey)
        defaults.removeObject(forKey: baseURLKey)
        defaults.removeObject(forKey: modelKey)
        defaults.removeObject(forKey: visionKey)
        for provider in AIProvider.allCases {
            KeychainHelper.delete(service: keychainService, account: provider.rawValue)
        }
    }
}

@MainActor
final class AISettingsViewModel: ObservableObject {
    @Published var provider: AIProvider
    @Published var baseURL: String
    @Published var model: String
    @Published var supportsVision: Bool
    @Published var apiKey: String
    @Published var statusMessage: String?
    @Published var isTesting = false

    init() {
        let settings = AISettingsStore.load()
        provider = settings.provider
        baseURL = settings.baseURL
        model = settings.model
        supportsVision = settings.supportsVision
        apiKey = AISettingsStore.apiKey(for: settings.provider)
    }

    var currentSettings: BYOSettings {
        BYOSettings(provider: provider, baseURL: baseURL, model: model, supportsVision: supportsVision)
    }

    var isConfigured: Bool {
        !baseURL.trimmingCharacters(in: .whitespaces).isEmpty
            && !model.trimmingCharacters(in: .whitespaces).isEmpty
            && !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func applyProviderDefaults() {
        baseURL = provider.defaultBaseURL
        model = provider.defaultModel
        supportsVision = provider.supportsVisionByDefault
        apiKey = AISettingsStore.apiKey(for: provider)
    }

    func save() {
        AISettingsStore.save(currentSettings)
        AISettingsStore.setAPIKey(apiKey, for: provider)
        statusMessage = "Saved. Your key stays in this device's Keychain."
    }

    func testConnection() async {
        isTesting = true
        statusMessage = nil
        do {
            let reply = try await OpenAICompatClient(settings: currentSettings, apiKey: apiKey)
                .complete(system: "You are a connectivity check. Reply with the single word OK.", user: "ping", maxTokens: 16)
            statusMessage = reply.isEmpty ? "Connected." : "Connected: \(reply.prefix(40))"
        } catch {
            statusMessage = error.localizedDescription
        }
        isTesting = false
    }
}
