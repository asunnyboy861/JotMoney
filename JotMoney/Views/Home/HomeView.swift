import SwiftUI
import SwiftData
import Combine

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.sortIndex) private var accounts: [Account]
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query private var budgets: [Budget]
    @Query private var rules: [RecurringRule]
    @Query private var plans: [InstallmentPlan]
    @Query private var memories: [MerchantMemory]

    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var voice = VoiceEntryService()
    @StateObject private var purchase = StoreManager.shared

    @State private var draft = ""
    @State private var pendingEntry: ParsedEntry?
    @State private var duplicateCandidate: ParsedEntry?
    @State private var duplicateHit: DuplicateHit?
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showReceiptPicker = false
    @State private var showScanMessage = false
    @State private var scanMessage = ""
    @State private var isScanning = false
    @State private var activeAccountID: UUID?

    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }

    private var currentAccount: Account? {
        if let activeAccountID, let match = activeAccounts.first(where: { $0.id == activeAccountID }) {
            return match
        }
        return activeAccounts.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    heroCard
                    quickStats
                    todaySection
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }

            QuickEntryBar(
                text: $draft,
                isListening: voice.isRecording,
                onSubmit: submitDraft,
                onVoice: toggleVoice,
                onReceipt: openReceipt
            )
        }
        .screenBackground()
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(item: $pendingEntry) { entry in
            ConfirmEntrySheet(parsed: entry, accounts: activeAccounts) { accountID, categoryKey in
                save(entry, accountID: accountID, categoryKey: categoryKey)
            }
        }
        .sheet(isPresented: $showReceiptPicker) {
            ReceiptCaptureView { image in
                showReceiptPicker = false
                handleReceipt(image)
            } onCancel: {
                showReceiptPicker = false
            }
            .ignoresSafeArea()
        }
        .alert("Possible duplicate", isPresented: Binding(
            get: { duplicateHit != nil },
            set: { if !$0 { duplicateHit = nil; duplicateCandidate = nil } }
        )) {
            Button("Merge") { resolveDuplicate(merge: true) }
            Button("Keep both") { resolveDuplicate(merge: false) }
            Button("Cancel", role: .cancel) { duplicateHit = nil; duplicateCandidate = nil }
        } message: {
            if let hit = duplicateHit {
                Text("\(hit.existing.displayMerchant) \(MoneyFormatter.string(hit.existing.amountCents)) was already logged on \(hit.existing.date.shortDayText).")
            }
        }
        .alert("Receipt scan", isPresented: $showScanMessage) {
            Button("OK", role: .cancel) { showScanMessage = false }
        } message: {
            Text(scanMessage)
        }
        .overlay {
            if isScanning {
                ZStack {
                    Color.black.opacity(0.55).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(Theme.mint)
                        Text("Reading your receipt…")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(24)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .onAppear {
            if activeAccountID == nil { activeAccountID = activeAccounts.first?.id }
            refresh()
        }
        .onChange(of: entries.count) { _, _ in refresh() }
        .onChange(of: budgets.count) { _, _ in refresh() }
        .onChange(of: voice.transcript) { _, newValue in
            if !newValue.isEmpty { draft = newValue }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("JotMoney")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text(currentAccount?.name ?? "No account")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            if activeAccounts.count > 1 {
                Menu {
                    ForEach(activeAccounts) { account in
                        Button {
                            activeAccountID = account.id
                        } label: {
                            Label(account.name, systemImage: account.kind.symbolName)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(Theme.surface)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Switch account")
            }
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 38, height: 38)
                    .background(Theme.surface)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var heroCard: some View {
        SurfaceCard(padding: 20) {
            HeroSafeToSpend(
                amountCents: viewModel.safeToSpendCents,
                progress: viewModel.progress,
                monthSpendCents: viewModel.monthSpendCents,
                daysLeft: viewModel.daysLeft
            )
        }
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            SurfaceCard(padding: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("NET WORTH")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(MoneyFormatter.string(viewModel.netWorthCents))
                        .font(.headline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .accessibilityElement(children: .combine)
            }
            SurfaceCard(padding: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TODAY")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Text(MoneyFormatter.string(viewModel.todaySpendCents))
                        .font(.headline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if viewModel.todayEntries.isEmpty {
                SurfaceCard {
                    EmptyStateView(
                        symbol: "bolt.horizontal",
                        title: "Nothing logged yet",
                        message: "Type “coffee 5.5” in the bar below and press return."
                    )
                }
            } else {
                SurfaceCard(padding: 14) {
                    VStack(spacing: 14) {
                        ForEach(viewModel.todayEntries) { entry in
                            TodayEntryRow(entry: entry)
                        }
                    }
                }
            }
        }
    }

    private func refresh() {
        viewModel.update(
            accounts: accounts,
            entries: entries,
            budgets: budgets,
            rules: rules,
            plans: plans,
            mode: AppPreferences.spendMode
        )
    }

    private func submitDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let accountID = currentAccount?.id else { return }
        guard let parsed = QuickEntryParser.parse(text, memories: memories) else {
            scanMessage = "Add an amount, like “coffee 5.5”."
            showScanMessage = true
            return
        }
        draft = ""
        if let hit = DuplicateDetector.check(
            amountCents: parsed.amountCents,
            merchantKey: parsed.merchantKey,
            date: Date(),
            type: parsed.type,
            in: entries
        ) {
            duplicateHit = hit
            duplicateCandidate = parsed
            return
        }
        if parsed.confidence >= 0.85 {
            save(parsed, accountID: accountID, categoryKey: parsed.categoryKey)
        } else {
            pendingEntry = parsed
        }
    }

    private func resolveDuplicate(merge: Bool) {
        guard let parsed = duplicateCandidate, let accountID = currentAccount?.id else {
            duplicateHit = nil
            duplicateCandidate = nil
            return
        }
        duplicateHit = nil
        duplicateCandidate = nil
        if merge {
            EntryService.shared.log(
                action: "entry.duplicateMerged",
                entityID: parsed.merchantKey,
                detail: "Skipped duplicate \(MoneyFormatter.string(parsed.amountCents))",
                context: context
            )
            EntryService.shared.save(context)
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            save(parsed, accountID: accountID, categoryKey: parsed.categoryKey)
        }
    }

    private func save(_ parsed: ParsedEntry, accountID: UUID, categoryKey: String) {
        EntryService.shared.commit(
            parsed: parsed,
            accountID: accountID,
            categoryKey: categoryKey,
            source: parsed.origin == .appleAI || parsed.origin == .byoAI ? .ocr : .quickEntry,
            context: context
        )
        pendingEntry = nil
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        refresh()
    }

    private func toggleVoice() {
        if voice.isRecording {
            voice.stop()
        } else {
            Task { await voice.start() }
        }
    }

    private func openReceipt() {
        let settings = AISettingsStore.load()
        let hasVisionKey = settings.supportsVision && settings.isConfigured
        if hasVisionKey || purchase.isPro {
            showReceiptPicker = true
            return
        }
        scanMessage = "Receipt scanning is a Pro feature, or add your own vision-capable AI key in Settings → AI."
        showScanMessage = true
    }

    private func handleReceipt(_ image: UIImage) {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else { return }
        let settings = AISettingsStore.load()
        let pro = purchase.isPro
        isScanning = true
        Task {
            do {
                let result = try await AIRouter.scanReceipt(jpeg: jpeg, settings: settings, isPro: pro)
                let parsed = ParsedEntry(
                    amountCents: result.totalCents,
                    merchantRaw: result.merchant,
                    merchantKey: LedgerEntry.normalizeMerchant(result.merchant),
                    categoryKey: result.categoryKey,
                    accountID: currentAccount?.id,
                    type: .expense,
                    confidence: result.confidence,
                    origin: .byoAI
                )
                isScanning = false
                pendingEntry = parsed
            } catch {
                isScanning = false
                scanMessage = error.localizedDescription
                showScanMessage = true
            }
        }
    }
}

extension ParsedEntry: Identifiable {
    var id: String { "\(merchantKey)-\(amountCents)-\(origin.rawValue)" }
}
