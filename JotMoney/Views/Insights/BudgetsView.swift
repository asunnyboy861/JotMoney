import SwiftUI
import SwiftData

struct BudgetsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var budgets: [Budget]
    @StateObject private var purchase = StoreManager.shared

    @State private var showAdd = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(budgets.filter { !$0.isArchived }) { budget in
                        SurfaceCard(padding: 14) {
                            HStack {
                                Image(systemName: EntryGlyph.symbol(for: budget.categoryKey))
                                    .foregroundStyle(Theme.mint)
                                Text(EntryGlyph.name(for: budget.categoryKey))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(MoneyFormatter.string(budget.limitCents))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                budget.isArchived = true
                                EntryService.shared.save(context)
                            } label: {
                                Label("Remove budget", systemImage: "trash")
                            }
                        }
                    }

                    Button("Add budget") {
                        if purchase.canAddBudget(currentCount: budgets.filter { !$0.isArchived }.count) {
                            showAdd = true
                        } else {
                            showPaywall = true
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Add budget")

                    Text("Free includes 1 budget. Pro is unlimited.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Budgets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .sheet(isPresented: $showAdd) { BudgetEditorSheet() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }
}

struct BudgetEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var categoryKey = DefaultCategoryKey.dining
    @State private var limitText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SurfaceCard {
                        HStack {
                            Text("Monthly limit").foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Text("$").foregroundStyle(Theme.textSecondary)
                            TextField("0.00", text: $limitText)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 120)
                                .foregroundStyle(Theme.textPrimary)
                                .accessibilityLabel("Monthly limit")
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
            .navigationTitle("New budget")
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
                        .disabled(limitText.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationBackground(Theme.background)
    }

    private func save() {
        let budget = Budget(categoryKey: categoryKey, limitCents: MoneyFormatter.decimalCents(limitText) ?? 0)
        context.insert(budget)
        EntryService.shared.save(context)
        dismiss()
    }
}
