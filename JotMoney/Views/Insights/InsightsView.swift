import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var accounts: [Account]
    @Query private var entries: [LedgerEntry]
    @Query private var rules: [RecurringRule]
    @Query private var plans: [InstallmentPlan]
    @Query private var budgets: [Budget]

    @StateObject private var viewModel = InsightsViewModel()
    @StateObject private var purchase = StoreManager.shared

    @State private var showPaywall = false
    @State private var showWrapped = false
    @State private var showBudgets = false
    @State private var showCoach = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    monthSummary
                    categoryBreakdown
                    budgetSection
                    forecastSection
                    radarSection
                    wrappedSection
                    coachSection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.vertical, 16)
                .padding(.bottom, 84)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .screenBackground()
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .onAppear(perform: refresh)
            .onChange(of: entries.count) { _, _ in refresh() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showWrapped) { MoneyWrappedView() }
            .sheet(isPresented: $showBudgets) { BudgetsView() }
            .sheet(isPresented: $showCoach) { MoneyCoachView() }
        }
    }

    private var monthSummary: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(Date().formatted(.dateTime.month(.wide).year()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(MoneyFormatter.string(viewModel.monthSpendCents))
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    Text("spent")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                StatRow(label: "Income", value: MoneyFormatter.string(viewModel.monthIncomeCents), valueColor: Theme.mint)
                StatRow(label: "Net worth", value: MoneyFormatter.string(viewModel.netWorthCents))
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Where it went")
            if viewModel.slices.isEmpty {
                SurfaceCard {
                    EmptyStateView(
                        symbol: "chart.pie",
                        title: "No spending yet",
                        message: "Log a few entries and your category breakdown appears here."
                    )
                }
            } else {
                SurfaceCard {
                    VStack(spacing: 14) {
                        ForEach(viewModel.slices.prefix(6)) { slice in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: slice.symbol)
                                        .font(.caption)
                                        .foregroundStyle(Theme.mint)
                                    Text(slice.name)
                                        .font(.subheadline)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(MoneyFormatter.string(slice.amountCents))
                                        .font(.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                GeometryReader { proxy in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Theme.separator)
                                        Capsule()
                                            .fill(Theme.mint.opacity(0.85))
                                            .frame(width: max(4, proxy.size.width * slice.share))
                                    }
                                }
                                .frame(height: 5)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
            }
        }
    }

    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Budgets")
                Spacer()
                Button(purchase.canAddBudget(currentCount: budgets.filter { !$0.isArchived }.count) ? "Manage" : "Manage (Pro)") {
                    if purchase.canAddBudget(currentCount: budgets.filter { !$0.isArchived }.count) {
                        showBudgets = true
                    } else {
                        showPaywall = true
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.mint)
            }
            if budgets.isEmpty {
                SurfaceCard {
                    EmptyStateView(
                        symbol: "target",
                        title: "No budget yet",
                        message: "Set one monthly limit and Safe to Spend will respect it."
                    )
                }
            } else {
                SurfaceCard {
                    VStack(spacing: 14) {
                        ForEach(budgets.filter { !$0.isArchived }) { budget in
                            budgetRow(budget)
                        }
                    }
                }
            }
        }
    }

    private func budgetRow(_ budget: Budget) -> some View {
        let spent = viewModel.slices.first { $0.id == budget.categoryKey }?.amountCents ?? 0
        let ratio = budget.limitCents > 0 ? min(1.2, Double(spent) / Double(budget.limitCents)) : 0
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(EntryGlyph.name(for: budget.categoryKey))
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(MoneyFormatter.string(spent)) of \(MoneyFormatter.string(budget.limitCents))")
                    .font(.caption)
                    .foregroundStyle(ratio >= 1 ? Theme.danger : Theme.textSecondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.separator)
                    Capsule()
                        .fill(ratio >= 1 ? Theme.danger : ratio > 0.8 ? Theme.warning : Theme.mint)
                        .frame(width: max(4, proxy.size.width * ratio))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
    }

    private var forecastSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("30-day forecast")
                if !purchase.isPro { ProBadge() }
            }
            if purchase.isPro {
                SurfaceCard {
                    if viewModel.forecast.isEmpty {
                        EmptyStateView(symbol: "chart.xyaxis.line", title: "Not enough data", message: "Log a few entries to build a forecast.")
                    } else {
                        Chart(viewModel.forecast) { point in
                            LineMark(
                                x: .value("Day", point.date),
                                y: .value("Balance", Double(point.balanceCents) / 100)
                            )
                            .foregroundStyle(Theme.mint)
                            .interpolationMethod(.catmullRom)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                        .frame(height: 180)
                        .accessibilityLabel("Projected balance for the next 30 days")
                    }
                }
            } else {
                lockedCard(message: "See the next 30 days of cash flow and catch shortfalls early.")
            }
        }
    }

    private var radarSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Subscription radar")
                if !purchase.isPro { ProBadge() }
            }
            if purchase.isPro {
                SurfaceCard {
                    if viewModel.radar.isEmpty {
                        EmptyStateView(symbol: "dot.radiowaves.left.and.right", title: "Nothing detected", message: "We flag merchants that charge a similar amount on a steady schedule.")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(viewModel.radar) { item in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.displayName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(Theme.textPrimary)
                                        Text("Every \(item.intervalDays) days · \(item.occurrences) charges")
                                            .font(.caption)
                                            .foregroundStyle(Theme.textSecondary)
                                    }
                                    Spacer()
                                    Text(MoneyFormatter.string(item.amountCents))
                                        .font(.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
            } else {
                lockedCard(message: "Find forgotten subscriptions hiding in your spending.")
            }
        }
    }

    private var wrappedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Money Wrapped")
            Button {
                showWrapped = true
            } label: {
                HStack {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                    Text("Create your month in review")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Create your Money Wrapped card")
        }
    }

    private var coachSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("Money Coach")
                if !purchase.isPro { ProBadge() }
            }
            Button {
                if purchase.isPro || AISettingsStore.load().isConfigured {
                    showCoach = true
                } else {
                    showPaywall = true
                }
            } label: {
                HStack {
                    Image(systemName: "bubble.left.and.text.bubble.right.fill")
                    Text("Ask about your spending")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .accessibilityLabel("Open Money Coach")
        }
    }

    private func lockedCard(message: String) -> some View {
        Button {
            showPaywall = true
        } label: {
            SurfaceCard {
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(Theme.mint)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.leading)
                        Text("Unlock with Pro")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.mint)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Pro feature. \(message)")
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(Theme.textPrimary)
    }

    private func refresh() {
        viewModel.update(accounts: accounts, entries: entries, rules: rules, plans: plans)
    }
}
