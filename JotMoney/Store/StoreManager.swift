import Foundation
import StoreKit
import Combine

@MainActor
final class StoreManager: ObservableObject {
    static let shared = StoreManager()

    static let monthlyID = "com.zzoutuo.jotmoney.pro.monthly"
    static let yearlyID = "com.zzoutuo.jotmoney.pro.yearly"
    static let familyID = "com.zzoutuo.jotmoney.family.yearly"
    static let lifetimeID = "com.zzoutuo.jotmoney.pro.lifetime"

    static let subscriptionIDs: [String] = [monthlyID, yearlyID, familyID]
    static let allIDs: [String] = subscriptionIDs + [lifetimeID]

    @Published var products: [Product] = []
    @Published var isPro: Bool = false
    @Published var isLifetime: Bool = false
    @Published var isLoading: Bool = false
    @Published var loadError: String?
    @Published var purchaseMessage: String?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    var monthlyProduct: Product? { products.first { $0.id == Self.monthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Self.yearlyID } }
    var familyProduct: Product? { products.first { $0.id == Self.familyID } }
    var lifetimeProduct: Product? { products.first { $0.id == Self.lifetimeID } }

    var sortedProducts: [Product] {
        products.sorted { rank($0.id) < rank($1.id) }
    }

    func rank(_ id: String) -> Int {
        switch id {
        case Self.yearlyID: return 0
        case Self.monthlyID: return 1
        case Self.familyID: return 2
        case Self.lifetimeID: return 3
        default: return 9
        }
    }

    func loadProducts() async {
        isLoading = true
        loadError = nil
        do {
            let fetched = try await Product.products(for: Self.allIDs)
            products = fetched
            if fetched.isEmpty {
                loadError = "Products are not available right now. Please try again later."
            }
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        purchaseMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlements()
                    purchaseMessage = "Purchase complete. Every Pro feature is unlocked."
                    return true
                case .unverified:
                    purchaseMessage = "The App Store could not verify this purchase."
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                purchaseMessage = "Your purchase is pending approval."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseMessage = "Purchase failed. Please try again."
            return false
        }
    }

    func restore() async {
        purchaseMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            purchaseMessage = isPro ? "Purchases restored." : "No previous purchase was found."
        } catch {
            purchaseMessage = "Restore failed. Please try again."
        }
    }

    func refreshEntitlements() async {
        var active = false
        var lifetime = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.revocationDate == nil else { continue }
            if transaction.productID == Self.lifetimeID {
                lifetime = true
                active = true
            } else if Self.subscriptionIDs.contains(transaction.productID) {
                if let expiration = transaction.expirationDate, expiration < Date() { continue }
                active = true
            }
        }
        isLifetime = lifetime
        isPro = active
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlements()
            }
        }
    }

    func canAddAccount(currentCount: Int) -> Bool {
        isPro || currentCount < 2
    }

    func canAddBudget(currentCount: Int) -> Bool {
        isPro || currentCount < 1
    }

    var canUseCloudAI: Bool { isPro }
    var canUseCloudFeatures: Bool { isPro }
}
