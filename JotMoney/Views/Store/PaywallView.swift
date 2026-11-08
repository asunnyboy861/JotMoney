import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var purchase = StoreManager.shared

    @State private var selectedProductID: String = StoreManager.yearlyID
    @State private var isPurchasing = false

    private var selectedProduct: Product? {
        purchase.products.first { $0.id == selectedProductID }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    featureList
                    productList
                    if let message = purchase.purchaseMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(message.contains("failed") ? Theme.warning : Theme.mint)
                    }
                    subscribeButton
                    legalSection
                    restoreButton
                }
                .padding(Theme.screenPadding)
                .padding(.bottom, 12)
            }
            .screenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .accessibilityLabel("Close")
                }
            }
            .task {
                if purchase.products.isEmpty {
                    await purchase.loadProducts()
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.mint)
            Text("Unlock every Pro feature")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Unlimited accounts and budgets, receipt scanning, forecasting, subscription radar, iCloud sync, and a shared ledger.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private var featureList: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                featureRow("infinity", "Unlimited accounts and budgets")
                featureRow("doc.viewfinder", "Receipt scanning with totals, tax, and tip")
                featureRow("chart.xyaxis.line", "30-day cash-flow forecast")
                featureRow("dot.radiowaves.left.and.right", "Subscription radar")
                featureRow("icloud.fill", "iCloud sync across your devices")
                featureRow("person.2.fill", "Shared ledger for your household")
                featureRow("sparkles", "Money Coach with your real numbers")
            }
        }
    }

    private var productList: some View {
        VStack(spacing: 10) {
            if purchase.isLoading {
                ProgressView().tint(Theme.mint).padding()
            } else if purchase.products.isEmpty {
                Text(purchase.loadError ?? "Purchase options are unavailable right now.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                Button("Try again") {
                    Task { await purchase.loadProducts() }
                }
                .buttonStyle(SecondaryButtonStyle())
            } else {
                ForEach(purchase.sortedProducts) { product in
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        let selected = product.id == selectedProductID
        return Button {
            selectedProductID = product.id
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Theme.mint : Theme.textSecondary)
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(periodText(product))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(14)
            .background(selected ? Theme.mint.opacity(0.10) : Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(selected ? Theme.mint : Theme.separator, lineWidth: selected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(product.displayName), \(product.displayPrice)")
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private func periodText(_ product: Product) -> String {
        if product.id == StoreManager.lifetimeID { return "One-time purchase · own it forever" }
        if product.id == StoreManager.yearlyID { return "Per year · 7-day free trial" }
        if product.id == StoreManager.familyID { return "Per year · up to 8 people" }
        return "Per month"
    }

    private var subscribeButton: some View {
        VStack(spacing: 8) {
            Button {
                guard let product = selectedProduct else { return }
                isPurchasing = true
                Task {
                    let success = await purchase.purchase(product)
                    isPurchasing = false
                    if success { dismiss() }
                }
            } label: {
                Text(isPurchasing ? "Processing…" : subscribeLabel)
            }
            .buttonStyle(PrimaryButtonStyle(enabled: selectedProduct != nil && !isPurchasing))
            .disabled(selectedProduct == nil || isPurchasing)
            .accessibilityLabel(subscribeLabel)

            Text(autoRenewDisclosure)
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var subscribeLabel: String {
        guard let product = selectedProduct else { return "Continue" }
        if product.id == StoreManager.lifetimeID { return "Buy once for \(product.displayPrice)" }
        return "Start \(product.displayName)"
    }

    private var autoRenewDisclosure: String {
        if selectedProductID == StoreManager.lifetimeID {
            return "One-time purchase. No subscription, no renewal."
        }
        return "Payment is charged to your Apple Account. Subscription renews automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel in Settings → Apple Account → Subscriptions."
    }

    private var legalSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                Link("Privacy Policy", destination: PolicyLinks.privacy)
                    .font(.caption2)
                    .foregroundStyle(Theme.mint)
                Link("Terms of Use", destination: PolicyLinks.terms)
                    .font(.caption2)
                    .foregroundStyle(Theme.mint)
                Link("Support", destination: PolicyLinks.support)
                    .font(.caption2)
                    .foregroundStyle(Theme.mint)
            }
            Text("JotMoney keeps your data on your device. No account, no analytics, no tracking.")
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await purchase.restore() }
        }
        .font(.footnote)
        .foregroundStyle(Theme.textSecondary)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Restore purchases")
    }

    private func featureRow(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .frame(width: 22)
                .foregroundStyle(Theme.mint)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Theme.textPrimary)
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
