import Foundation
import Observation
import UIKit

@Observable
@MainActor
class WatchlistViewModel {
    static let shared = WatchlistViewModel()

    var items: [WatchlistItem] = []
    var isLoading = false
    var errorMessage: String?

    // Local watchlist for users who haven't signed in
    // Stores search results locally until auth is set up
    var localItems: [LocalWatchlistItem] = []

    // Refresh state
    var isRefreshing = false
    var lastRefreshAt: Date? {
        didSet {
            UserDefaults.standard.set(lastRefreshAt, forKey: Constants.UserDefaultsKeys.lastWatchlistRefresh)
        }
    }

    init() {
        loadLocalItems()
        lastRefreshAt = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.lastWatchlistRefresh) as? Date
    }

    var displayItems: [LocalWatchlistItem] {
        localItems
    }

    var isAtFreeLimit: Bool {
        localItems.count >= Constants.freeWatchlistLimit
    }

    /// Pro users track unlimited items; free users get `freeWatchlistLimit`.
    var canAddMore: Bool {
        ProManager.shared.isPro || !isAtFreeLimit
    }

    var itemCount: Int {
        localItems.count
    }

    // MARK: - Local Watchlist (Pre-Auth MVP)

    func addItem(from result: ProductSearchResult) {
        guard canAddMore else { return }

        // Don't add duplicates
        if localItems.contains(where: { $0.query.lowercased() == result.query.lowercased() }) {
            return
        }

        let item = LocalWatchlistItem(
            id: UUID().uuidString,
            productName: result.product,
            query: result.query,
            verdict: result.verdict,
            confidence: result.confidence,
            shortReason: result.shortReason,
            bestPrice: result.bestPrice?.price,
            bestRetailer: result.bestPrice?.retailer,
            addedAt: Date(),
            productImage: result.productImage,
            previousPrice: nil,
            lastCheckedAt: Date()
        )

        localItems.insert(item, at: 0)
        saveLocalItems()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        Analytics.track("watchlist_added", properties: ["product": result.product])
    }

    func removeItem(id: String) {
        let name = localItems.first(where: { $0.id == id })?.productName ?? "unknown"
        localItems.removeAll { $0.id == id }
        saveLocalItems()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        Analytics.track("watchlist_removed", properties: ["product": name])
    }

    func isInWatchlist(query: String) -> Bool {
        localItems.contains { $0.query.lowercased() == query.lowercased() }
    }

    // MARK: - Price Refresh

    /// Refreshes stale watchlist items (oldest first, capped per pass to
    /// control API cost) and returns any detected price drops / verdict
    /// flips so callers can fire alerts.
    ///
    /// - Parameter force: ignore the per-item staleness window (used by
    ///   pull-to-refresh). Items checked in the last 30 minutes are always
    ///   skipped — the server cache would return identical data anyway.
    @discardableResult
    func refreshPrices(force: Bool = false) async -> [PriceDrop] {
        guard !isRefreshing, !localItems.isEmpty else { return [] }
        isRefreshing = true
        defer { isRefreshing = false }

        let minInterval: TimeInterval = force ? 30 * 60 : Constants.refreshStaleness
        let now = Date()

        let staleIDs = localItems
            .filter { item in
                guard let checked = item.lastCheckedAt else { return true }
                return now.timeIntervalSince(checked) > minInterval
            }
            .sorted { ($0.lastCheckedAt ?? .distantPast) < ($1.lastCheckedAt ?? .distantPast) }
            .prefix(Constants.refreshBatchSize)
            .map(\.id)

        guard !staleIDs.isEmpty else { return [] }

        var drops: [PriceDrop] = []

        for id in staleIDs {
            guard let index = localItems.firstIndex(where: { $0.id == id }) else { continue }
            let item = localItems[index]

            guard let result = try? await APIClient.shared.searchProduct(query: item.query) else {
                continue
            }
            // Item may have been removed while we were fetching
            guard let freshIndex = localItems.firstIndex(where: { $0.id == id }) else { continue }

            var updated = localItems[freshIndex]
            let oldPrice = updated.bestPrice
            let oldVerdict = updated.verdictType

            if let newBest = result.bestPrice?.price, newBest > 0 {
                if let old = oldPrice, old > 0, old != newBest {
                    updated.previousPrice = old
                }
                updated.bestPrice = newBest
                updated.bestRetailer = result.bestPrice?.retailer
            }
            updated.verdict = result.verdict
            updated.confidence = result.confidence
            updated.shortReason = result.shortReason
            if let image = result.productImage {
                updated.productImage = image
            }
            updated.lastCheckedAt = Date()
            localItems[freshIndex] = updated

            // Detect alert-worthy changes
            if let old = oldPrice, old > 0,
               let newBest = result.bestPrice?.price, newBest > 0, newBest < old {
                drops.append(PriceDrop(
                    itemID: updated.id,
                    productName: updated.productName,
                    kind: .priceDrop(oldPrice: old, newPrice: newBest)
                ))
            } else if oldVerdict != .buyNow, updated.verdictType == .buyNow {
                drops.append(PriceDrop(
                    itemID: updated.id,
                    productName: updated.productName,
                    kind: .verdictFlippedToBuy
                ))
            }
        }

        lastRefreshAt = Date()
        saveLocalItems()
        Analytics.track("watchlist_refreshed", properties: [
            "checked": staleIDs.count, "drops": drops.count, "forced": force
        ])
        return drops
    }

    /// Auto-refresh on app open — only when something is actually stale.
    func refreshIfStale() async {
        let hasStale = localItems.contains { item in
            guard let checked = item.lastCheckedAt else { return true }
            return Date().timeIntervalSince(checked) > Constants.refreshStaleness
        }
        guard hasStale else { return }
        let drops = await refreshPrices()
        await AlertsManager.notify(drops: drops, currencySymbol: regionCurrencySymbol)
    }

    var regionCurrencySymbol: String {
        let saved = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.selectedRegion) ?? ""
        let region = saved.isEmpty ? (Locale.current.region?.identifier ?? "US") : saved
        let map: [String: String] = [
            "US": "$", "IN": "₹", "GB": "£", "DE": "€",
            "CA": "CA$", "AU": "A$", "JP": "¥", "FR": "€",
        ]
        return map[region] ?? "$"
    }

    // MARK: - Persistence (UserDefaults for MVP, SwiftData later)

    private func loadLocalItems() {
        guard let data = UserDefaults.standard.data(forKey: Constants.UserDefaultsKeys.watchlist),
              let items = try? JSONDecoder().decode([LocalWatchlistItem].self, from: data) else {
            return
        }
        localItems = items
    }

    private func saveLocalItems() {
        guard let data = try? JSONEncoder().encode(localItems) else { return }
        UserDefaults.standard.set(data, forKey: Constants.UserDefaultsKeys.watchlist)
    }
}

// MARK: - Local Watchlist Item

struct LocalWatchlistItem: Codable, Identifiable, Sendable {
    let id: String
    let productName: String
    let query: String
    var verdict: String
    var confidence: Double
    var shortReason: String
    var bestPrice: Int?
    var bestRetailer: String?
    let addedAt: Date
    var productImage: String?
    // New in 1.1 — optional so items saved by 1.0 decode cleanly
    var previousPrice: Int?
    var lastCheckedAt: Date?

    var verdictType: VerdictType {
        VerdictType(rawValue: verdict) ?? .wait
    }

    /// Positive when the price went down since the last check.
    var priceDropAmount: Int? {
        guard let previous = previousPrice, let current = bestPrice,
              previous > current, current > 0 else { return nil }
        return previous - current
    }
}
