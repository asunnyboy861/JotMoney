import SwiftUI
import SwiftData

struct MoneyCoachView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
    @Query private var entries: [LedgerEntry]
    @StateObject private var purchase = StoreManager.shared

    @State private var question = ""
    @State private var answer = ""
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your month at a glance")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(summary)
                                .font(.caption)
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }

                    TextField("Ask about your spending…", text: $question, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(14)
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundStyle(Theme.textPrimary)
                        .accessibilityLabel("Your question")

                    Button(isWorking ? "Thinking…" : "Ask Coach") {
                        ask()
                    }
                    .buttonStyle(PrimaryButtonStyle(enabled: !question.trimmingCharacters(in: .whitespaces).isEmpty && !isWorking))
                    .disabled(question.trimmingCharacters(in: .whitespaces).isEmpty || isWorking)
                    .accessibilityLabel("Ask Money Coach")

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Theme.warning)
                    }

                    if !answer.isEmpty {
                        SurfaceCard {
                            Text(answer)
                                .font(.subheadline)
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(Theme.screenPadding)
            }
            .screenBackground()
            .navigationTitle("Money Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.mint)
                }
            }
        }
    }

    private var summary: String {
        let monthSpend = BalanceEngine.monthTotal(entries: entries, type: .expense)
        let monthIncome = BalanceEngine.monthTotal(entries: entries, type: .income)
        let totals = BalanceEngine.categoryTotals(entries: entries)
        let top = totals.max(by: { $0.value < $1.value })
        let topText = top.map { "\(EntryGlyph.name(for: $0.key)) \(MoneyFormatter.string($0.value))" } ?? "no category yet"
        return "Spent \(MoneyFormatter.string(monthSpend)), income \(MoneyFormatter.string(monthIncome)). Biggest category: \(topText)."
    }

    private func ask() {
        let prompt = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty else { return }
        isWorking = true
        errorMessage = nil
        answer = ""
        let settings = AISettingsStore.load()
        let pro = purchase.isPro
        Task {
            do {
                let reply = try await AIRouter.coach(question: prompt, summary: summary, settings: settings, isPro: pro)
                answer = reply
            } catch {
                errorMessage = error.localizedDescription
            }
            isWorking = false
        }
    }
}
