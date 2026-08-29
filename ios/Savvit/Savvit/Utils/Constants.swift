import Foundation

enum Constants {
    static let apiBaseURL = "https://savvit-api.onrender.com"
    static let freeWatchlistLimit = 3
    static let maxRecentSearches = 10

    // MARK: - Savvit Pro (StoreKit 2)

    static let proMonthlyID = "app.savvit.pro.monthly"
    static let proYearlyID = "app.savvit.pro.yearly"
    static let proProductIDs: Set<String> = [proMonthlyID, proYearlyID]

    // MARK: - Watchlist refresh

    /// Matches the server's price cache TTL — refreshing more often just
    /// returns the same cached result while still counting against rate limits.
    static let refreshStaleness: TimeInterval = 6 * 60 * 60
    /// Max items refreshed per pass, oldest-checked first (cost control).
    static let refreshBatchSize = 6
    static let bgRefreshTaskID = "app.savvit.ios.refresh"

    enum UserDefaultsKeys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let recentSearches = "recentSearches"
        static let selectedRegion = "selectedRegion"
        static let searchCount = "searchCount"
        static let hasRequestedReview = "hasRequestedReview"
        static let watchlist = "savvit_watchlist"
        static let isProCached = "savvit_pro_cached"
        static let alertsEnabled = "savvit_alerts_enabled"
        static let lastWatchlistRefresh = "savvit_watchlist_last_refresh"
    }
}
