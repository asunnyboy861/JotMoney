import SwiftUI
import SwiftData

struct EntryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.sortIndex) private var accounts: [Account]

    let entry: LedgerEntry

    @State private var amountText = ""
    @State private var merchant = ""
    @State private var categoryKey = DefaultCategoryKey.other
    @State private var accountID = UUID()
    @State private var note = ""
    @State private var date = Date()
    @State private var type: EntryType = .expense
    @State private var showArchiveConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Amount")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Theme.textSecondary)
                            HStack(spacing: 6) {
                                Text("$")
                                    .font(.title2.weight(.semibold))
                                    .foregroundStyle(Theme.textSecondary)
                                TextField("0.00", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(Theme.textPrimary)
                                    .accessibilityLabel("Amount in dollars")
                            }
                            Picker("Type", selection: $type) {
                                ForEach(EntryType.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Theme.mint)
                        }
                    }

                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Merchant", text: $merchant)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.textPrimary)
                                .accessibilityLabel("Merchant")
                            Divider().overlay(Theme.separator)
                            DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .tint(Theme.mint)
                                .foregroundStyle(Theme.textPrimary)
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Account")
                                    .foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Picker("Account", selection: $accountID) {
                                    ForEach(accounts.filter { !$0.isArchived }) { account in
                                        Text(account.name).tag(account.id)
                                    }
                                }
                                .tint(Theme.mint)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Category")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                        FlexibleChips(items: DefaultCategoryKey.all, selectedKey: categoryKey) { key in
                            categoryKey = key
                        }
                    }

                    SurfaceCard {
                        TextField("Note", text: $note, axis: .vertical)
                            .lineLimit(2...5)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Theme.textPrimary)
                            .accessibilityLabel("Note")
                    }

                    Button("Archive entry", role: .destructive) {
                        showArchiveConfirm = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.danger)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("Archive this entry")
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Edit entry")
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
                        .accessibilityLabel("Save changes")
                }
            }
            .confirmationDialog("Archive this entry?", isPresented: $showArchiveConfirm, titleVisibility: .visible) {
                Button("Archive", role: .destructive) {
                    EntryService.shared.archive(entry, context: context)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Archived entries stay in your data but are removed from totals.")
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        amountText = MoneyFormatter.amountText(entry.amountCents)
        merchant = entry.merchantRaw
        categoryKey = entry.categoryKey
        accountID = entry.accountID
        note = entry.note
        date = entry.date
        type = entry.type
    }

    private func save() {
        entry.amountCents = MoneyFormatter.decimalCents(amountText) ?? entry.amountCents
        entry.merchantRaw = merchant
        entry.merchantKey = LedgerEntry.normalizeMerchant(merchant)
        entry.categoryKey = categoryKey
        entry.accountID = accountID
        entry.note = note
        entry.date = date
        entry.type = type
        EntryService.shared.log(
            action: "entry.edited",
            entityID: entry.id.uuidString,
            detail: entry.displayMerchant,
            context: context
        )
        EntryService.shared.save(context)
        dismiss()
    }
}
