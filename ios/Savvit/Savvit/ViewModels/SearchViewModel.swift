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
        showVerdict = true
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
        } catch {
            loadingTask.cancel()
            isLoading = false
            showVerdict = false
            if error.localizedDescription.contains("timed out") {
                errorMessage = "Server is warming up. Please try again in a moment."
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    var isResolvingURL = false
    var resolvedProductName: String?

    func searchRecent(_ query: String) {
        searchQuery = query
        Task { await search() }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Unified Search (text or URL)

    /// Detects if the query is a URL. If so, resolves it client-side first.
    func unifiedSearch() async {
        let input = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }

        if isURL(input) {
            await searchFromURL(input)
        } else {
            await search()
        }
    }

    private func searchFromURL(_ urlString: String) async {
        isResolvingURL = true
        resolvedProductName = nil

        do {
            let productName = try await resolveProductURL(urlString)
            resolvedProductName = productName
            searchQuery = productName
            isResolvingURL = false
            await search()
        } catch {
            isResolvingURL = false
            errorMessage = "Couldn't identify product from that link. Try searching by name instead."
        }
    }

    // MARK: - URL Detection

    func isURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return trimmed.hasPrefix("http://")
            || trimmed.hasPrefix("https://")
            || trimmed.hasPrefix("amzn.in/")
            || trimmed.hasPrefix("amzn.to/")
            || trimmed.hasPrefix("dl.flipkart.com/")
            || trimmed.hasPrefix("fkrt.it/")
            || trimmed.contains("amazon.") && trimmed.contains("/dp/")
            || trimmed.contains("flipkart.com/")
    }

    // MARK: - Client-Side URL Resolution

    /// Resolves a short/full product URL to a product name entirely on-device.
    /// Strategy: follow redirects (phone isn't blocked like cloud servers) → extract name from URL slug.
    private func resolveProductURL(_ urlString: String) async throws -> String {
        var urlStr = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlStr.lowercased().hasPrefix("http") {
            urlStr = "https://" + urlStr
        }

        guard let url = URL(string: urlStr) else {
            throw URLError(.badURL)
        }

        // Follow redirects to get the final URL
        let config = URLSessionConfiguration.ephemeral
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
        ]
        let session = URLSession(configuration: config)

        let (_, response) = try await session.data(from: url)
        let finalURL = response.url ?? url
        let finalURLString = finalURL.absoluteString

        // Try to extract product name from known URL slug patterns
        if let name = extractFromAmazonURL(finalURL) ?? extractFromFlipkartURL(finalURL) ?? extractFromCromaURL(finalURL) {
            return name
        }

        // Try to get page title (works well on phone — not blocked like servers)
        if let title = try? await fetchPageTitle(url: finalURL, session: session) {
            return title
        }

        // Amazon fallback: if we have an ASIN, search with it directly
        // Perplexity knows what every ASIN is
        if let asin = extractASIN(from: finalURL) {
            return "Amazon ASIN \(asin)"
        }

        // Flipkart fallback: extract item ID
        if let fkItem = extractFlipkartItemID(from: finalURL) {
            return "Flipkart item \(fkItem)"
        }

        throw NSError(domain: "Savvit", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not identify product"])
    }

    private func extractFromAmazonURL(_ url: URL) -> String? {
        let components = url.pathComponents
        // Pattern: /Product-Name/dp/ASIN — need slug BEFORE /dp/
        if let dpIndex = components.firstIndex(of: "dp"), dpIndex > 1 {
            let slug = components[dpIndex - 1]
                .replacingOccurrences(of: "-", with: " ")
                .trimmingCharacters(in: .whitespaces)
            // Make sure slug is a real product name, not just "/" or a short fragment
            if slug.count > 5 && slug != "/" && !slug.contains("amazon") {
                return slug
            }
        }
        return nil
    }

    /// Extract ASIN (10-char alphanumeric ID) from any Amazon URL
    private func extractASIN(from url: URL) -> String? {
        let components = url.pathComponents
        if let dpIndex = components.firstIndex(of: "dp"),
           dpIndex + 1 < components.count {
            let asin = components[dpIndex + 1]
            // ASIN is always 10 alphanumeric characters
            if asin.count == 10 && asin.allSatisfy({ $0.isLetter || $0.isNumber }) {
                return asin
            }
        }
        // Also check query params (some URLs have ?asin=)
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let asin = queryItems.first(where: { $0.name.lowercased() == "asin" })?.value {
            return asin
        }
        return nil
    }

    /// Extract Flipkart item ID from URL
    private func extractFlipkartItemID(from url: URL) -> String? {
        let components = url.pathComponents
        if let pIndex = components.firstIndex(of: "p"),
           pIndex + 1 < components.count {
            let itemId = components[pIndex + 1]
            if itemId.count > 3 { return itemId }
        }
        // Check query param: ?pid=
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
           let pid = queryItems.first(where: { $0.name.lowercased() == "pid" })?.value {
            return pid
        }
        return nil
    }

    private func extractFromFlipkartURL(_ url: URL) -> String? {
        let components = url.pathComponents
        // Pattern: /product-name/p/ITEMID
        if let pIndex = components.firstIndex(of: "p"), pIndex > 1 {
            let slug = components[pIndex - 1]
                .replacingOccurrences(of: "-", with: " ")
                .trimmingCharacters(in: .whitespaces)
            if slug.count > 3 && slug != "/" { return slug }
        }
        return nil
    }

    private func extractFromCromaURL(_ url: URL) -> String? {
        let components = url.pathComponents
        if let pIndex = components.firstIndex(of: "p"), pIndex > 1 {
            let slug = components[pIndex - 1]
                .replacingOccurrences(of: "-", with: " ")
                .trimmingCharacters(in: .whitespaces)
            if slug.count > 3 && slug != "/" { return slug }
        }
        return nil
    }

    private func fetchPageTitle(url: URL, session: URLSession) async throws -> String? {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: request)
        guard let html = String(data: data, encoding: .utf8) else { return nil }

        // Extract <title> tag
        guard let titleStart = html.range(of: "<title", options: .caseInsensitive),
              let tagEnd = html[titleStart.upperBound...].range(of: ">"),
              let titleEnd = html[tagEnd.upperBound...].range(of: "</title>", options: .caseInsensitive)
        else { return nil }

        var title = String(html[tagEnd.upperBound..<titleEnd.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Clean common retailer suffixes
        let suffixes = [
            " - Amazon.in", " : Amazon.in", " | Amazon.in",
            " - Flipkart.com", " | Flipkart.com",
            " - Buy Online", " | Buy Online",
            "Online at Best Price", " at Best Price in India",
            " | Croma", " - Croma"
        ]
        for suffix in suffixes {
            if let range = title.range(of: suffix, options: .caseInsensitive) {
                title = String(title[..<range.lowerBound])
            }
        }

        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.count > 3 ? title : nil
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
