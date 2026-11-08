import SwiftUI

struct HeroSafeToSpend: View {
    let amountCents: Int64
    let progress: Double
    let monthSpendCents: Int64
    let daysLeft: Int

    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 76

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("SAFE TO SPEND")
                    .font(.caption.weight(.semibold))
                    .tracking(1.4)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text("\(daysLeft) days left")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Text(MoneyFormatter.string(amountCents))
                .font(.system(size: min(heroSize, 92), weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .accessibilityLabel("Safe to spend \(MoneyFormatter.string(amountCents))")

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.separator)
                    Capsule()
                        .fill(progress >= 1 ? Theme.danger : Theme.mint)
                        .frame(width: max(6, proxy.size.width * min(1, progress)))
                }
            }
            .frame(height: 6)

            HStack {
                Text("Spent this month \(MoneyFormatter.string(monthSpendCents))")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(progressLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(progress >= 1 ? Theme.danger : Theme.textSecondary)
            }
        }
    }

    private var progressLabel: String {
        "\(Int(min(1, progress) * 100))% of budget"
    }
}

struct TodayEntryRow: View {
    let entry: LedgerEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.surface)
                    .frame(width: 38, height: 38)
                Image(systemName: EntryGlyph.symbol(for: entry.categoryKey))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.mint)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayMerchant)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text("\(EntryGlyph.name(for: entry.categoryKey)) · \(entry.date.timeText)")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            Text(entry.type == .income ? "+\(MoneyFormatter.string(entry.amountCents))" : "−\(MoneyFormatter.string(entry.amountCents))")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(entry.type == .income ? Theme.mint : Theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

enum EntryGlyph {
    static func symbol(for categoryKey: String) -> String {
        DefaultCategoryKey.all.first { $0.key == categoryKey }?.symbol ?? "square.grid.2x2.fill"
    }

    static func name(for categoryKey: String) -> String {
        DefaultCategoryKey.all.first { $0.key == categoryKey }?.name ?? "Other"
    }
}
