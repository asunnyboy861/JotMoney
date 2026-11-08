import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @Query private var entries: [LedgerEntry]

    @StateObject private var purchase = StoreManager.shared
    @State private var showAdd = false
    @State private var showPaywall = false

    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("NET WORTH")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                            Text(MoneyFormatter.string(BalanceEngine.netWorth(accounts: accounts, entries: entries)))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    ForEach(activeAccounts) { account in
                        SurfaceCard(padding: 14) {
                            HStack(spacing: 12) {
                                Image(systemName: account.kind.symbolName)
                                    .font(.headline)
                                    .foregroundStyle(Theme.mint)
                                    .frame(width: 34, height: 34)
                                    .background(Theme.background)
                                    .clipShape(Circle())
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(account.name)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("\(account.kind.title) · \(account.currencyCode)")
                                        .font(.caption)
                                        .foregroundStyle(Theme.textSecondary)
                                }
                                Spacer()
                                Text(MoneyFormatter.string(BalanceEngine.balanceCents(for: account, entries: entries)))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(account.isLiability ? Theme.warning : Theme.textPrimary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                account.isArchived = true
                                EntryService.shared.log(action: "account.archived", entityID: account.id.uuidString, detail: account.name, context: context)
                                EntryService.shared.save(context)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                    }

                    Button {
                        if purchase.canAddAccount(currentCount: activeAccounts.count) {
                            showAdd = true
                        } else {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text(purchase.isPro || activeAccounts.count < 2 ? "Add account" : "Add account (Pro)")
                            if !purchase.isPro && activeAccounts.count >= 2 { ProBadge() }
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Add account")

                    Text("Free includes 2 accounts. Pro is unlimited.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Accounts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .sheet(isPresented: $showAdd) {
                AccountEditorSheet()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

struct AccountEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var kind: AccountKind = .checking
    @State private var openingText = "0"
    @State private var aprText = ""
    @State private var currency = "USD"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Account name", text: $name)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.textPrimary)
                                .accessibilityLabel("Account name")
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Type").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Picker("Type", selection: $kind) {
                                    ForEach(AccountKind.allCases) { item in
                                        Text(item.title).tag(item)
                                    }
                                }
                                .tint(Theme.mint)
                            }
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Opening balance").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Text("$").foregroundStyle(Theme.textSecondary)
                                TextField("0.00", text: $openingText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                    .foregroundStyle(Theme.textPrimary)
                                    .accessibilityLabel("Opening balance")
                            }
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("APR % (optional)").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                TextField("0", text: $aprText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .foregroundStyle(Theme.textPrimary)
                                    .accessibilityLabel("Annual percentage rate")
                            }
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Currency").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                TextField("USD", text: $currency)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 80)
                                    .foregroundStyle(Theme.textPrimary)
                                    .accessibilityLabel("Currency code")
                            }
                        }
                    }
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("New account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .font(.headline)
                        .foregroundStyle(Theme.mint)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.background)
    }

    private func save() {
        let account = Account(
            name: name.trimmingCharacters(in: .whitespaces),
            kind: kind,
            openingBalanceCents: MoneyFormatter.decimalCents(openingText) ?? 0
        )
        account.currencyCode = currency.uppercased()
        if let apr = Double(aprText.replacingOccurrences(of: ",", with: ".")) {
            account.aprBps = Int((apr * 100).rounded())
        }
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortIndex, order: .reverse)])
        account.sortIndex = ((try? context.fetch(descriptor).first?.sortIndex) ?? 0) + 1
        context.insert(account)
        EntryService.shared.log(action: "account.created", entityID: account.id.uuidString, detail: account.name, context: context)
        EntryService.shared.save(context)
        dismiss()
    }
}
