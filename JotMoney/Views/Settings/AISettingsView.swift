import SwiftUI

struct AISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AISettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: AppleIntelligenceService.isAvailable ? "checkmark.seal.fill" : "info.circle.fill")
                            .foregroundStyle(AppleIntelligenceService.isAvailable ? Theme.mint : Theme.warning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Intelligence")
                                .font(.subheadline.weight(.semibold))
                            Text(AppleIntelligenceService.isAvailable
                                 ? "On-device AI is available and free to use."
                                 : "Requires iOS 26 and a supported device. Use your own key below.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                } header: {
                    Text("On-device")
                }

                Section {
                    Picker("Provider", selection: $viewModel.provider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.title).tag(provider)
                        }
                    }
                    .tint(Theme.mint)
                    .onChange(of: viewModel.provider) { _, _ in
                        viewModel.applyProviderDefaults()
                    }

                    TextField("Base URL", text: $viewModel.baseURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .accessibilityLabel("Base URL")

                    TextField("Model", text: $viewModel.model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Model name")

                    SecureField("API key", text: $viewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .accessibilityLabel("API key")

                    Toggle("Vision (receipt scanning)", isOn: $viewModel.supportsVision)
                        .tint(Theme.mint)
                        .accessibilityLabel("Vision support for receipt scanning")
                } header: {
                    Text("Your own key")
                } footer: {
                    Text("Keys are stored in the iOS Keychain on this device only. Receipt scanning needs a vision-capable model. Any OpenAI-compatible endpoint works.")
                        .font(.caption2)
                }

                Section {
                    Button("Save") {
                        viewModel.save()
                    }
                    .foregroundStyle(Theme.mint)
                    .accessibilityLabel("Save AI settings")

                    Button(viewModel.isTesting ? "Testing…" : "Test connection") {
                        Task { await viewModel.testConnection() }
                    }
                    .foregroundStyle(Theme.mint)
                    .disabled(!viewModel.isConfigured || viewModel.isTesting)
                    .accessibilityLabel("Test AI connection")

                    if let status = viewModel.statusMessage {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("AI never blocks the core ledger. Balance, Safe to Spend, installments, and interest are always computed on device.")
                        .font(.caption2)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
        }
    }
}
