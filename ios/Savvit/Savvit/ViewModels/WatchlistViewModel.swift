import Foundation
import Observation
import UIKit

@Observable
@MainActor
class WatchlistViewModel {
    var items: [WatchlistItem] = []
    var isLoading = false
    var errorMessage: String?

    // Local watchlist for users who haven't signed in
    // Stores search results locally until auth is set up
    var localItems: [LocalWatchlistItem] = []

    init() {
        loadLocalItems()
    }

    var displayItems: [LocalWatchlistItem] {
        localItems
    }

    var isAtFreeLimit: Bool {
        localItems.count >= Constants.freeWatchlistLimit
    }

    var itemCount: Int {
        localItems.count
    }

    // MARK: - Local Watchlist (Pre-Auth MVP)

    func addItem(from result: ProductSearchResult) {
        guard !isAtFreeLimit else { return }

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
            productImage: result.productImage
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

    // MARK: - Persistence (UserDefaults for MVP, SwiftData later)

    private func loadLocalItems() {
        guard let data = UserDefaults.standard.data(forKey: "savvit_watchlist"),
              let items = try? JSONDecoder().decode([LocalWatchlistItem].self, from: data) else {
            return
        }
        localItems = items
    }

    private func saveLocalItems() {
        guard let data = try? JSONEncoder().encode(localItems) else { return }
        UserDefaults.standard.set(data, forKey: "savvit_watchlist")
    }
}

// MARK: - Local Watchlist Item

struct LocalWatchlistItem: Codable, Identifiable, Sendable {
    let id: String
    let productName: String
    let query: String
    let verdict: String
    let confidence: Double
    let shortReason: String
    let bestPrice: Int?
    let bestRetailer: String?
    let addedAt: Date
    let productImage: String?

    var verdictType: VerdictType {
        VerdictType(rawValue: verdict) ?? .wait
    }
}
