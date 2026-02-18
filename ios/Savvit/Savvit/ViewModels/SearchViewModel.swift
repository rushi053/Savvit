import Foundation
import Observation

@Observable
@MainActor
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
            try? await Task.sleep(for: .seconds(7))
            if !Task.isCancelled { loadingStep = "Almost there..." }
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
            if error.localizedDescription.contains("timed out") {
                errorMessage = "Server is warming up. Please try again in a moment."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func searchFromURL(_ urlString: String) async {
        let productName = extractProductName(from: urlString)
        searchQuery = productName ?? urlString
        await search()
    }

    func searchRecent(_ query: String) {
        searchQuery = query
        Task { await search() }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - URL Product Name Extraction

    private func extractProductName(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let host = url.host?.lowercased() ?? ""

        // Amazon: /dp/ASIN or /product-name/dp/ASIN
        if host.contains("amazon") {
            let pathComponents = url.pathComponents
            if let dpIndex = pathComponents.firstIndex(of: "dp"), dpIndex > 1 {
                let name = pathComponents[dpIndex - 1]
                    .replacingOccurrences(of: "-", with: " ")
                    .trimmingCharacters(in: .whitespaces)
                if !name.isEmpty && name != "/" { return name }
            }
        }

        // Flipkart: /product-name/p/ITEMID
        if host.contains("flipkart") {
            let pathComponents = url.pathComponents
            if let pIndex = pathComponents.firstIndex(of: "p"), pIndex > 1 {
                let name = pathComponents[pIndex - 1]
                    .replacingOccurrences(of: "-", with: " ")
                    .trimmingCharacters(in: .whitespaces)
                if !name.isEmpty && name != "/" { return name }
            }
        }

        return nil
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
