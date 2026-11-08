import SwiftUI
import SwiftData

struct RecurringView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var rules: [RecurringRule]

    @State private var showAdd = false

    private var activeRules: [RecurringRule] { rules.filter { $0.isActive } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if activeRules.isEmpty {
                        SurfaceCard {
                            EmptyStateView(
                                symbol: "arrow.triangle.2.circlepath",
                                title: "No recurring rules",
                                message: "Add rent, subscriptions, or a paycheck and future entries appear automatically."
                            )
                        }
                    } else {
                        ForEach(activeRules) { rule in
                            SurfaceCard(padding: 14) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(rule.merchantRaw)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("\(rule.cadence.title) · next \(nextText(rule))")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Text(rule.type == .income ? "+\(MoneyFormatter.string(rule.amountCents))" : MoneyFormatter.string(rule.amountCents))
                                        .font(.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(rule.type == .income ? Theme.mint : Theme.textPrimary)
                                }
                                .accessibilityElement(children: .combine)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    rule.isActive = false
                                    EntryService.shared.save(context)
                                } label: {
                                    Label("Stop rule", systemImage: "stop.circle")
                                }
                            }
                        }
                    }

                    Button("Add recurring rule") { showAdd = true }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel("Add recurring rule")

                    Text("Rules are the source of truth. Deleting a generated entry never deletes the rule.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .sheet(isPresented: $showAdd) {
                RecurringEditorSheet()
            }
        }
    }

    private func nextText(_ rule: RecurringRule) -> String {
        let calendar = Calendar.current
        let base = rule.lastGeneratedDate ?? rule.anchorDate
        let next = calendar.date(byAdding: rule.cadence.component, value: rule.cadence.step, to: base) ?? base
        return next.shortDayText
    }
}

struct RecurringEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.sortIndex) private var accounts: [Account]

    @State private var merchant = ""
    @State private var amountText = ""
    @State private var cadence: CadenceType = .monthly
    @State private var anchorDate = Date()
    @State private var accountID = UUID()
    @State private var type: EntryType = .expense
    @State private var categoryKey = DefaultCategoryKey.bills

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Merchant", text: $merchant)
                                .textFieldStyle(.plain)
                                .foregroundStyle(Theme.textPrimary)
                                .accessibilityLabel("Merchant")
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Amount").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Text("$").foregroundStyle(Theme.textSecondary)
                                TextField("0.00", text: $amountText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                    .foregroundStyle(Theme.textPrimary)
                                    .accessibilityLabel("Amount")
                            }
                            Divider().overlay(Theme.separator)
                            Picker("Type", selection: $type) {
                                ForEach(EntryType.allCases) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .pickerStyle(.segmented)
                            .tint(Theme.mint)
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Cadence").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Picker("Cadence", selection: $cadence) {
                                    ForEach(CadenceType.allCases) { item in
                                        Text(item.title).tag(item)
                                    }
                                }
                                .tint(Theme.mint)
                            }
                            Divider().overlay(Theme.separator)
                            DatePicker("Starts", selection: $anchorDate, displayedComponents: .date)
                                .tint(Theme.mint)
                                .foregroundStyle(Theme.textPrimary)
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Account").foregroundStyle(Theme.textSecondary)
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
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("New rule")
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
                        .disabled(amountText.isEmpty)
                }
            }
            .onAppear {
                if accountID == UUID(), let first = accounts.first(where: { !$0.isArchived }) {
                    accountID = first.id
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Theme.background)
    }

    private func save() {
        let rule = RecurringRule(
            merchantRaw: merchant.isEmpty ? "Recurring" : merchant,
            amountCents: MoneyFormatter.decimalCents(amountText) ?? 0,
            type: type,
            categoryKey: categoryKey,
            accountID: accountID,
            cadence: cadence,
            anchorDate: anchorDate
        )
        context.insert(rule)
        EntryService.shared.save(context)
        dismiss()
    }
}
