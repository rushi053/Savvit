import Foundation

enum Constants {
    static let apiBaseURL = "https://savvit-api.onrender.com"
    static let freeWatchlistLimit = 3
    static let maxRecentSearches = 10

    enum UserDefaultsKeys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let recentSearches = "recentSearches"
    }
}
