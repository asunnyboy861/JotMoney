import SwiftUI
import SwiftData

struct ConfirmEntrySheet: View {
    let parsed: ParsedEntry
    let accounts: [Account]
    let onSave: (UUID, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var categoryKey: String
    @State private var accountID: UUID
    @State private var note = ""

    init(parsed: ParsedEntry, accounts: [Account], onSave: @escaping (UUID, String) -> Void) {
        self.parsed = parsed
        self.accounts = accounts
        self.onSave = onSave
        _categoryKey = State(initialValue: parsed.categoryKey)
        _accountID = State(initialValue: parsed.accountID ?? accounts.first?.id ?? UUID())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(parsed.type == .income ? "Income" : "Expense")
                            .font(.caption.weight(.semibold))
                            .tracking(1.2)
                            .foregroundStyle(Theme.textSecondary)
                        Text(MoneyFormatter.string(parsed.amountCents))
                            .font(.system(size: 44, weight: .bold, design: .rounded))
                            .foregroundStyle(Theme.textPrimary)
                            .contentTransition(.numericText())
                        Text(parsed.merchantRaw)
                            .font(.headline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityElement(children: .combine)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        FlexibleChips(items: DefaultCategoryKey.all, selectedKey: categoryKey) { key in
                            categoryKey = key
                        }
                    }

                    if accounts.count > 1 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Account")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                            Picker("Account", selection: $accountID) {
                                ForEach(accounts) { account in
                                    Text(account.name).tag(account.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Theme.mint)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Note")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("Optional note", text: $note, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(14)
                            .background(Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .foregroundStyle(Theme.textPrimary)
                            .accessibilityLabel("Note")
                    }

                    if parsed.needsConfirmation {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Theme.warning)
                            Text("Filled from your input. Adjust anything before saving.")
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Confirm entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(accountID, categoryKey)
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundStyle(Theme.mint)
                    .accessibilityLabel("Save transaction")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.background)
    }
}

struct FlexibleChips: View {
    let items: [(key: String, name: String, symbol: String)]
    let selectedKey: String
    let onSelect: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.key) { item in
                CategoryChip(name: item.name, symbol: item.symbol, isSelected: item.key == selectedKey) {
                    onSelect(item.key)
                }
            }
        }
    }
}
