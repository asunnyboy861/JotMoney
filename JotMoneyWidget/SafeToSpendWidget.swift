import WidgetKit
import SwiftUI

struct SafeToSpendEntry: TimelineEntry {
    let date: Date
    let amountCents: Int64
}

struct SafeToSpendProvider: TimelineProvider {
    func placeholder(in context: Context) -> SafeToSpendEntry {
        SafeToSpendEntry(date: .now, amountCents: 4218)
    }

    func getSnapshot(in context: Context, completion: @escaping (SafeToSpendEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SafeToSpendEntry>) -> Void) {
        let defaults = UserDefaults(suiteName: "group.com.zzoutuo.JotMoney")
        let cents = defaults?.object(forKey: "safeToSpendCents") as? Int64 ?? 0
        let entry = SafeToSpendEntry(date: .now, amountCents: cents)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
    }
}

struct SafeToSpendWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SafeToSpendWidget", provider: SafeToSpendProvider()) { entry in
            SafeToSpendWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Safe to Spend")
        .description("See what you can safely spend today.")
        .supportedFamilies([.accessoryInline, .accessoryCircular])
    }
}

struct SafeToSpendWidgetView: View {
    let entry: SafeToSpendEntry

    var body: some View {
        Text("Safe to spend \(formatted(entry.amountCents))")
    }

    private func formatted(_ cents: Int64) -> String {
        let value = Double(cents) / 100.0
        return value.formatted(.currency(code: "USD"))
    }
}

@main
struct JotMoneyWidgetBundle: WidgetBundle {
    var body: some Widget {
        SafeToSpendWidget()
    }
}
