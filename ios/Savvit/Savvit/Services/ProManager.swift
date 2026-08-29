import Foundation
import Observation
import StoreKit

/// Savvit Pro subscription state, built directly on StoreKit 2.
///
/// Free tier: 3 watchlist items, full verdicts.
/// Pro: unlimited watchlist, price-drop alerts, auto refresh.
@Observable
@MainActor
final class ProManager {
    static let shared = ProManager()

    /// Cached so gating works instantly on launch and offline; corrected by
    /// `refreshEntitlements()` as soon as StoreKit answers.
    private(set) var isPro: Bool = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.isProCached)

    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var purchaseInFlight = false
    var lastError: String?

    private var updatesTask: Task<Void, Never>?

    private init() {
        updatesTask = Task { await listenForTransactionUpdates() }
        Task {
            await refreshEntitlements()
            await loadProductsIfNeeded()
        }
    }

    var monthlyProduct: Product? { products.first { $0.id == Constants.proMonthlyID } }
    var yearlyProduct: Product? { products.first { $0.id == Constants.proYearlyID } }

    // MARK: - Products

    func loadProductsIfNeeded() async {
        guard products.isEmpty, !isLoadingProducts else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let loaded = try await Product.products(for: Constants.proProductIDs)
            products = loaded.sorted { $0.price < $1.price }
            lastError = nil
        } catch {
            lastError = "Couldn't load plans. Check your connection and try again."
        }
    }

    // MARK: - Purchase / Restore

    /// Returns true if the user ends up with an active Pro entitlement.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        guard !purchaseInFlight else { return isPro }
        purchaseInFlight = true
        defer { purchaseInFlight = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                }
                await refreshEntitlements()
                if isPro {
                    Analytics.track("pro_purchased", properties: ["product": product.id])
                }
                return isPro
            case .userCancelled:
                Analytics.track("pro_purchase_cancelled", properties: ["product": product.id])
                return isPro
            case .pending:
                // Ask-to-buy etc. — entitlement arrives later via Transaction.updates
                return isPro
            @unknown default:
                return isPro
            }
        } catch {
            lastError = "Purchase failed. You haven't been charged."
            Analytics.track("pro_purchase_failed", properties: ["product": product.id])
            return isPro
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            // sync throwing usually means the user cancelled the App Store sign-in
        }
        await refreshEntitlements()
        Analytics.track("pro_restore_tapped", properties: ["restored": isPro])
    }

    // MARK: - Entitlements

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Constants.proProductIDs.contains(transaction.productID),
               transaction.revocationDate == nil {
                active = true
            }
        }
        setPro(active)
    }

    private func listenForTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                await transaction.finish()
            }
            await refreshEntitlements()
        }
    }

    private func setPro(_ value: Bool) {
        if isPro != value {
            isPro = value
            Analytics.track("pro_status_changed", properties: ["isPro": value])
        }
        UserDefaults.standard.set(value, forKey: Constants.UserDefaultsKeys.isProCached)
    }
}
