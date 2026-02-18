import Foundation
import Observation

@Observable
class SearchViewModel {
    var searchQuery = ""
    var isLoading = false
    var loadingStep = ""
    var searchResult: ProductSearchResult?
    var errorMessage: String?
    var showVerdict = false
    var recentSearches: [String] = []

    init() {
        loadRecentSearches()
    }

    func search() async {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        searchResult = nil
        showVerdict = false
        loadingStep = "Checking retailers..."

        let loadingTask = Task {
            try? await Task.sleep(for: .seconds(3))
            if !Task.isCancelled { loadingStep = "Analyzing prices..." }
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled { loadingStep = "Generating verdict..." }
        }

        do {
            let result = try await APIClient.shared.searchProduct(query: query)
            loadingTask.cancel()
            searchResult = result
            saveToRecentSearches(query)
            isLoading = false
            showVerdict = true
        } catch {
            loadingTask.cancel()
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }

    func searchRecent(_ query: String) {
        searchQuery = query
        Task { await search() }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Recent Searches

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(
            forKey: Constants.UserDefaultsKeys.recentSearches
        ) ?? []
    }

    private func saveToRecentSearches(_ query: String) {
        recentSearches.removeAll { $0.lowercased() == query.lowercased() }
        recentSearches.insert(query, at: 0)
        if recentSearches.count > Constants.maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(Constants.maxRecentSearches))
        }
        UserDefaults.standard.set(recentSearches, forKey: Constants.UserDefaultsKeys.recentSearches)
    }
}
