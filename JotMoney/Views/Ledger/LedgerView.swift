import SwiftUI
import SwiftData

struct LedgerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \Account.sortIndex) private var accounts: [Account]

    @State private var searchText = ""
    @State private var showAccounts = false
    @State private var showRecurring = false
    @State private var showInstallments = false
    @State private var editingEntry: LedgerEntry?
    @State private var exportURL: URL?
    @State private var showShare = false

    private var visibleAccounts: [Account] { accounts.filter { !$0.isArchived } }

    private var filteredEntries: [LedgerEntry] {
        let base = entries.filter { !$0.isArchived }
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter {
            $0.merchantRaw.lowercased().contains(query)
                || $0.note.lowercased().contains(query)
                || EntryGlyph.name(for: $0.categoryKey).lowercased().contains(query)
        }
    }

    private var grouped: [(day: Date, items: [LedgerEntry])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredEntries) { calendar.startOfDay(for: $0.date) }
        return groups.map { (day: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if grouped.isEmpty {
                        SurfaceCard {
                            EmptyStateView(
                                symbol: "list.bullet.rectangle",
                                title: "No transactions yet",
                                message: "Entries you log on Home appear here, grouped by day."
                            )
                        }
                    } else {
                        ForEach(grouped, id: \.day) { group in
                            daySection(day: group.day, items: group.items)
                        }
                    }
                }
                .padding(.horizontal, Theme.screenPadding)
                .padding(.vertical, 16)
                .padding(.bottom, 84)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .screenBackground()
            .searchable(text: $searchText, prompt: "Search merchant, note, category")
            .navigationTitle("Ledger")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { showAccounts = true } label: { Label("Accounts", systemImage: "building.columns") }
                        Button { showRecurring = true } label: { Label("Recurring", systemImage: "arrow.triangle.2.circlepath") }
                        Button { showInstallments = true } label: { Label("Installments", systemImage: "calendar.badge.clock") }
                        Button { exportCSV() } label: { Label("Export CSV", systemImage: "square.and.arrow.up") }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundStyle(Theme.mint)
                    }
                    .accessibilityLabel("Ledger actions")
                }
            }
            .sheet(isPresented: $showAccounts) { AccountsView() }
            .sheet(isPresented: $showRecurring) { RecurringView() }
            .sheet(isPresented: $showInstallments) { InstallmentsView() }
            .sheet(item: $editingEntry) { entry in
                EntryEditorView(entry: entry)
            }
            .sheet(isPresented: $showShare) {
                if let exportURL {
                    ShareSheet(items: [exportURL])
                }
            }
        }
    }

    private func daySection(day: Date, items: [LedgerEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayText(day))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(MoneyFormatter.string(items.filter { $0.type == .expense }.reduce(Int64(0)) { $0 + $1.amountCents }))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Theme.textSecondary)
            }
            SurfaceCard(padding: 12) {
                VStack(spacing: 10) {
                    ForEach(items) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            HStack {
                                TodayEntryRow(entry: entry)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                EntryService.shared.archive(entry, context: context)
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayText(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    private func exportCSV() {
        let rows = entries.filter { !$0.isArchived }.map { entry -> String in
            let iso = ISO8601DateFormatter().string(from: entry.date)
            let merchant = entry.merchantRaw.replacingOccurrences(of: ",", with: " ")
            return "\(iso),\(entry.type.title),\(merchant),\(EntryGlyph.name(for: entry.categoryKey)),\(MoneyFormatter.amountText(entry.amountCents)),\(entry.source.title)"
        }
        let csv = (["date,type,merchant,category,amount,source"] + rows).joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("JotMoney-Export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showShare = true
        } catch {
            exportURL = nil
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
