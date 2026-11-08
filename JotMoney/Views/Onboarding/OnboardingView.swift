import SwiftUI
import SwiftData

struct OnboardingView: View {
    let onComplete: () -> Void

    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var accountName = "Checking"
    @State private var accountKind: AccountKind = .checking
    @State private var openingBalanceText = "500"
    @State private var demoText = "coffee 4.5"
    @State private var createdAccountID: UUID?
    @State private var entryLogged = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("JotMoney")
                    .font(.headline)
                    .foregroundStyle(Theme.mint)
                Spacer()
                if step > 0 && step < 2 {
                    Button("Skip") { finish() }
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, Theme.screenPadding)
            .padding(.top, 12)

            TabView(selection: $step) {
                manifesto.tag(0)
                accountStep.tag(1)
                firstEntryStep.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? Theme.mint : Theme.separator)
                        .frame(width: index == step ? 22 : 8, height: 8)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private var manifesto: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Image(systemName: "bolt.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Theme.mint)
            Text("Type it.\nDone.")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("No sign-up. Your data stays on this phone.")
                .font(.title3)
                .foregroundStyle(Theme.textSecondary)
            Text("Logging money takes two seconds: type “coffee 5.5”, hit return, and the amount, merchant, and category are filled in for you.")
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Button("Continue") {
                withAnimation { step = 1 }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel("Continue to create your first account")
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.bottom, 24)
    }

    private var accountStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text("Add your first account")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Thirty seconds, once. You can add more later.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 14) {
                TextField("Account name", text: $accountName)
                    .textFieldStyle(.plain)
                    .padding(14)
                    .background(Theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityLabel("Account name")

                HStack(spacing: 8) {
                    ForEach(AccountKind.allCases) { kind in
                        Button {
                            accountKind = kind
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: kind.symbolName)
                                    .font(.subheadline)
                                Text(kind.title)
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .foregroundStyle(accountKind == kind ? Color.black : Theme.textSecondary)
                            .background(accountKind == kind ? Theme.mint : Theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(kind.title) account type")
                    }
                }

                HStack {
                    Text("Opening balance")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Text("$")
                        .foregroundStyle(Theme.textSecondary)
                    TextField("0.00", text: $openingBalanceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                        .foregroundStyle(Theme.textPrimary)
                        .accessibilityLabel("Opening balance in dollars")
                }
                .padding(14)
                .background(Theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Spacer()
            Button("Create account") {
                createAccount()
            }
            .buttonStyle(PrimaryButtonStyle(enabled: !accountName.trimmingCharacters(in: .whitespaces).isEmpty))
            .disabled(accountName.trimmingCharacters(in: .whitespaces).isEmpty)
            .accessibilityLabel("Create account and continue")

            Button("Skip for now") { finish() }
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.bottom, 24)
    }

    private var firstEntryStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Text(entryLogged ? "Logged." : "Try your first entry")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text(entryLogged ? "That is the whole loop. Two seconds, done." : "Type an amount and a merchant. We fill in the rest.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            HStack(spacing: 10) {
                Image(systemName: "text.cursor")
                    .foregroundStyle(Theme.mint)
                TextField("coffee 4.5", text: $demoText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.textPrimary)
                    .submitLabel(.done)
                    .onSubmit { logDemoEntry() }
                    .accessibilityLabel("Quick entry text")
            }
            .padding(16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if entryLogged {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.mint)
                    Text("First transaction saved")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .accessibilityElement(children: .combine)
            }

            Spacer()
            Button(entryLogged ? "Open JotMoney" : "Log it") {
                if entryLogged { finish() } else { logDemoEntry() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityLabel(entryLogged ? "Open JotMoney" : "Log the sample transaction")

            Button("Skip") { finish() }
                .font(.footnote)
                .foregroundStyle(Theme.textSecondary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.screenPadding)
        .padding(.bottom, 24)
    }

    private func createAccount() {
        let cents = MoneyFormatter.decimalCents(openingBalanceText) ?? 0
        let account = Account(name: accountName, kind: accountKind, openingBalanceCents: cents)
        context.insert(account)
        EntryService.shared.save(context)
        createdAccountID = account.id
        withAnimation { step = 2 }
    }

    private func logDemoEntry() {
        guard let accountID = resolveAccountID() else {
            finish()
            return
        }
        guard let parsed = QuickEntryParser.parse(demoText) else { return }
        EntryService.shared.commit(
            parsed: parsed,
            accountID: accountID,
            categoryKey: parsed.categoryKey,
            source: .quickEntry,
            context: context
        )
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation { entryLogged = true }
    }

    private func resolveAccountID() -> UUID? {
        if let createdAccountID { return createdAccountID }
        let descriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortIndex)])
        if let first = try? context.fetch(descriptor).first {
            createdAccountID = first.id
            return first.id
        }
        let fallback = Account(name: "Checking", kind: .checking, openingBalanceCents: 0)
        context.insert(fallback)
        EntryService.shared.save(context)
        createdAccountID = fallback.id
        return fallback.id
    }

    private func finish() {
        let descriptor = FetchDescriptor<Account>()
        let existing = (try? context.fetch(descriptor)) ?? []
        if existing.isEmpty {
            let account = Account(name: "Checking", kind: .checking, openingBalanceCents: 0)
            context.insert(account)
            EntryService.shared.save(context)
        }
        onComplete()
    }
}
