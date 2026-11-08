import SwiftUI
import SwiftData

struct MoneyWrappedView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var entries: [LedgerEntry]

    @State private var shareImage: UIImage?
    @State private var showShare = false

    private var monthEntries: [LedgerEntry] {
        let calendar = Calendar.current
        return entries.filter {
            !$0.isArchived && $0.type == .expense && calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
    }

    private var totalCents: Int64 {
        monthEntries.reduce(Int64(0)) { $0 + $1.amountCents }
    }

    private var largest: LedgerEntry? {
        monthEntries.max { $0.amountCents < $1.amountCents }
    }

    private var topMerchant: (name: String, count: Int)? {
        let grouped = Dictionary(grouping: monthEntries) { $0.merchantKey }
        guard let best = grouped.max(by: { $0.value.count < $1.value.count }) else { return nil }
        return (best.value.first?.displayMerchant ?? best.key, best.value.count)
    }

    private var topCategory: CategorySlice? {
        let totals = BalanceEngine.categoryTotals(entries: entries)
        guard let best = totals.max(by: { $0.value < $1.value }) else { return nil }
        return CategorySlice(
            id: best.key,
            name: EntryGlyph.name(for: best.key),
            symbol: EntryGlyph.symbol(for: best.key),
            amountCents: best.value,
            share: totalCents > 0 ? Double(best.value) / Double(totalCents) : 0
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    wrappedCard
                        .frame(maxWidth: 360)
                        .aspectRatio(9.0 / 16.0, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

                    Button("Share card") {
                        render()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .accessibilityLabel("Share your Money Wrapped card")

                    Text("The card carries a #JotMoney watermark. Sharing is entirely optional and stays on this device.")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Money Wrapped")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
            .sheet(isPresented: $showShare) {
                if let shareImage {
                    ShareSheet(items: [shareImage])
                }
            }
        }
    }

    private var wrappedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("JotMoney")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.mint)
                Spacer()
                Text(Date().formatted(.dateTime.month(.abbreviated).year()))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.bottom, 22)

            Text("You spent")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text(MoneyFormatter.string(totalCents))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer(minLength: 18)

            VStack(alignment: .leading, spacing: 16) {
                wrappedStat(title: "Biggest single charge", value: largest.map { "\($0.displayMerchant) \(MoneyFormatter.string($0.amountCents))" } ?? "—")
                wrappedStat(title: "Most visited", value: topMerchant.map { "\($0.name) ×\($0.count)" } ?? "—")
                wrappedStat(title: "Top category", value: topCategory.map { "\($0.name) \(MoneyFormatter.string($0.amountCents))" } ?? "—")
            }

            Spacer()

            HStack {
                Text("#JotMoney")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.mint)
                Spacer()
                Text("Type it. Done.")
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(24)
        .background(
            LinearGradient(colors: [Theme.background, Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(Theme.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    private func wrappedStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(Theme.textSecondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
        }
    }

    private func render() {
        let renderer = ImageRenderer(content: wrappedCard.frame(width: 1080, height: 1920))
        renderer.scale = 2
        if let image = renderer.uiImage {
            shareImage = image
            showShare = true
        }
    }
}
