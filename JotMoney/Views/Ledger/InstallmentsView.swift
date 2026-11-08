import SwiftUI
import SwiftData

struct InstallmentsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var plans: [InstallmentPlan]

    @State private var showAdd = false
    @State private var errorMessage: String?

    private var activePlans: [InstallmentPlan] { plans.filter { !$0.isArchived } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if activePlans.isEmpty {
                        SurfaceCard {
                            EmptyStateView(
                                symbol: "calendar.badge.clock",
                                title: "No installment plans",
                                message: "Add a Buy Now Pay Later plan and JotMoney schedules every charge date for you."
                            )
                        }
                    } else {
                        ForEach(activePlans) { plan in
                            planCard(plan)
                        }
                    }

                    Button("Add installment plan") { showAdd = true }
                        .buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel("Add installment plan")
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Installments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .sheet(isPresented: $showAdd) {
                InstallmentEditorSheet()
            }
            .alert("Installment error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func planCard(_ plan: InstallmentPlan) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(plan.merchantRaw)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text("\(plan.generatedCount)/\(plan.periodCount)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                HStack {
                    Text(MoneyFormatter.string(plan.perPeriodCents))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.mint)
                    Text(plan.cadence.title.lowercased())
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("Total \(MoneyFormatter.string(plan.totalCents))")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                if let next = InstallmentEngine.nextChargeDate(plan: plan) {
                    Text("Next charge \(next.shortDayText)")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                HStack(spacing: 8) {
                    ForEach(Array(InstallmentEngine.schedule(plan: plan).enumerated()), id: \.offset) { item in
                        Capsule()
                            .fill(item.offset < plan.generatedCount ? Theme.mint : Theme.separator)
                            .frame(height: 5)
                    }
                }
                .accessibilityLabel("\(plan.generatedCount) of \(plan.periodCount) periods charged")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                plan.isArchived = true
                EntryService.shared.save(context)
            } label: {
                Label("Archive plan", systemImage: "archivebox")
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct InstallmentEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.sortIndex) private var accounts: [Account]

    @State private var merchant = ""
    @State private var totalText = ""
    @State private var perPeriodText = ""
    @State private var periodCount = 4
    @State private var firstChargeDate = Date()
    @State private var cadence: CadenceType = .biweekly
    @State private var accountID = UUID()
    @State private var categoryKey = DefaultCategoryKey.shopping
    @State private var errorMessage: String?

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
                                Text("Total").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Text("$").foregroundStyle(Theme.textSecondary)
                                TextField("0.00", text: $totalText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                    .foregroundStyle(Theme.textPrimary)
                                    .accessibilityLabel("Plan total")
                            }
                            Divider().overlay(Theme.separator)
                            HStack {
                                Text("Per period").foregroundStyle(Theme.textSecondary)
                                Spacer()
                                Text("$").foregroundStyle(Theme.textSecondary)
                                TextField("0.00", text: $perPeriodText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 110)
                                    .foregroundStyle(Theme.textPrimary)
                                    .accessibilityLabel("Amount per period")
                            }
                            Divider().overlay(Theme.separator)
                            Stepper("\(periodCount) payments", value: $periodCount, in: 2...36)
                                .foregroundStyle(Theme.textPrimary)
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
                            DatePicker("First charge", selection: $firstChargeDate, displayedComponents: .date)
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

                    Button("Use Klarna 4-payment template") {
                        periodCount = 4
                        cadence = .biweekly
                        if let total = MoneyFormatter.decimalCents(totalText) {
                            perPeriodText = MoneyFormatter.amountText(total / 4)
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .accessibilityLabel("Apply Klarna four payment template")

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
            .navigationTitle("New plan")
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
                }
            }
            .alert("Check the plan", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
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
        guard let total = MoneyFormatter.decimalCents(totalText), total > 0 else {
            errorMessage = "Enter a total greater than zero."
            return
        }
        var perPeriod = MoneyFormatter.decimalCents(perPeriodText) ?? 0
        if perPeriod == 0 {
            perPeriod = (total / Int64(periodCount)) + (total % Int64(periodCount) > 0 ? 1 : 0)
        }
        let plan = InstallmentPlan(
            merchantRaw: merchant.isEmpty ? "Installment" : merchant,
            totalCents: total,
            perPeriodCents: perPeriod,
            periodCount: periodCount,
            firstChargeDate: firstChargeDate,
            cadence: cadence,
            accountID: accountID,
            categoryKey: categoryKey
        )
        do {
            try InstallmentEngine.validate(plan)
        } catch {
            errorMessage = error.localizedDescription
            return
        }
        context.insert(plan)
        EntryService.shared.save(context)
        EntryService.shared.materializeInstallments(context: context)
        dismiss()
    }
}
