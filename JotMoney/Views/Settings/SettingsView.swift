import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @StateObject private var purchase = StoreManager.shared
    @State private var showPaywall = false
    @State private var showAccounts = false
    @State private var showAI = false
    @State private var showContact = false
    @State private var iCloudEnabled = AppPreferences.iCloudSyncEnabled
    @State private var spendMode = AppPreferences.spendMode
    @State private var showRestartNote = false

    var body: some View {
        NavigationStack {
            Form {
                proSection
                accountSection
                aiSection
                preferencesSection
                supportSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .onAppear {
                Task { await purchase.refreshEntitlements() }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showAccounts) { AccountsView() }
            .sheet(isPresented: $showAI) { AISettingsView() }
            .sheet(isPresented: $showContact) { ContactSupportView() }
            .alert("Restart to apply", isPresented: $showRestartNote) {
                Button("OK", role: .cancel) { showRestartNote = false }
            } message: {
                Text("Quit and reopen JotMoney to switch the data store. Your entries are always kept locally.")
            }
        }
    }

    private var proSection: some View {
        Section {
            if purchase.isPro {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.mint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(purchase.isLifetime ? "BYO Lifetime" : "JotMoney Pro")
                            .font(.subheadline.weight(.semibold))
                        Text("Every Pro feature is unlocked.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(Theme.mint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to Pro")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Unlimited accounts, receipts, forecast, sync.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .accessibilityLabel("Upgrade to Pro")
            }
            Button("Restore Purchases") {
                Task { await purchase.restore() }
            }
            .font(.subheadline)
            .foregroundStyle(Theme.mint)
            .accessibilityLabel("Restore purchases")
        } header: {
            Text("Membership")
        }
    }

    private var accountSection: some View {
        Section {
            Button {
                showAccounts = true
            } label: {
                settingsRow(symbol: "building.columns.fill", title: "Accounts", detail: "Balances and net worth")
            }
            .accessibilityLabel("Accounts")
        } header: {
            Text("Money")
        }
    }

    private var aiSection: some View {
        Section {
            Button {
                showAI = true
            } label: {
                settingsRow(symbol: "sparkles", title: "AI", detail: "Your own key or Apple Intelligence")
            }
            .accessibilityLabel("AI settings")
        } header: {
            Text("Intelligence")
        } footer: {
            Text("Your API key is stored only in this device's Keychain. JotMoney never sends your ledger to a server of ours.")
                .font(.caption2)
        }
    }

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { iCloudEnabled },
                set: { newValue in
                    iCloudEnabled = newValue
                    AppPreferences.iCloudSyncEnabled = newValue
                    if newValue { showRestartNote = true }
                }
            )) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Sync")
                    Text("Optional. Off by default.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Theme.mint)
            .accessibilityLabel("iCloud Sync")

            Picker(selection: Binding(
                get: { spendMode },
                set: { newValue in
                    spendMode = newValue
                    AppPreferences.spendMode = newValue
                }
            )) {
                ForEach(SpendMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            } label: {
                Text("Safe to Spend style")
            }
            .tint(Theme.mint)
            .accessibilityLabel("Safe to Spend style")
        } header: {
            Text("Preferences")
        }
    }

    private var supportSection: some View {
        Section {
            Button {
                showContact = true
            } label: {
                settingsRow(symbol: "envelope.fill", title: "Contact Support", detail: "We reply by email")
            }
            .accessibilityLabel("Contact Support")

            Link(destination: PolicyLinks.support) {
                settingsRow(symbol: "questionmark.circle.fill", title: "Help & FAQ", detail: nil)
            }
            Link(destination: PolicyLinks.privacy) {
                settingsRow(symbol: "hand.raised.fill", title: "Privacy Policy", detail: nil)
            }
            Link(destination: PolicyLinks.terms) {
                settingsRow(symbol: "doc.text.fill", title: "Terms of Use", detail: nil)
            }
        } header: {
            Text("Support")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("JotMoney")
                Spacer()
                Text(AppVersionInfo.display)
                    .foregroundStyle(.secondary)
            }
            .font(.footnote)
            .accessibilityElement(children: .combine)
        } header: {
            Text("About")
        } footer: {
            Text("No account. No analytics. Your ledger stays on your device unless you turn on iCloud Sync.")
                .font(.caption2)
        }
    }

    private func settingsRow(symbol: String, title: String, detail: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.mint)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(.primary)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
