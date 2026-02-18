import Foundation

// MARK: - API Errors

enum APIError: LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    case decodingError(String)
    case serverError(String)
    case watchlistLimit
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Invalid URL"
        case .networkError(let msg): msg
        case .decodingError(let msg): "Failed to parse response: \(msg)"
        case .serverError(let msg): msg
        case .watchlistLimit: "Free plan allows up to 3 items"
        case .unauthorized: "Please sign in to continue"
        }
    }
}

private struct APIErrorResponse: Codable, Sendable {
    let error: String
}

// MARK: - API Client

final class APIClient: Sendable {
    static let shared = APIClient()

    private let authTokenStore = AuthTokenStore()

    func setAuthToken(_ token: String?) {
        authTokenStore.set(token)
    }

    private var authToken: String? {
        authTokenStore.get()
    }

    // MARK: - Product Search (no auth needed)

    func searchProduct(query: String) async throws -> ProductSearchResult {
        guard let url = URL(string: "\(Constants.apiBaseURL)/v1/products/search") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(["query": query])

        let (data, response) = try await performRequest(request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid server response")
        }

        guard httpResponse.statusCode == 200 else {
            let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(
                errorBody?.error ?? "Server error (\(httpResponse.statusCode))"
            )
        }

        do {
            return try JSONDecoder().decode(ProductSearchResult.self, from: data)
        } catch {
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Watchlist

    func getWatchlist() async throws -> WatchlistResponse {
        guard let token = authToken else { throw APIError.unauthorized }
        let request = makeAuthedRequest(path: "/v1/watchlist", method: "GET", token: token)
        let (data, response) = try await performRequest(request)
        try checkResponse(response, data: data)
        return try JSONDecoder().decode(WatchlistResponse.self, from: data)
    }

    func addToWatchlist(productName: String, query: String, sourceUrl: String? = nil, targetPrice: Int? = nil) async throws -> WatchlistAddResponse {
        guard let token = authToken else { throw APIError.unauthorized }
        var request = makeAuthedRequest(path: "/v1/watchlist", method: "POST", token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "productName": productName,
            "query": query
        ]
        if let sourceUrl { body["sourceUrl"] = sourceUrl }
        if let targetPrice { body["targetPrice"] = targetPrice }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await performRequest(request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403 {
            throw APIError.watchlistLimit
        }
        try checkResponse(response, data: data)
        return try JSONDecoder().decode(WatchlistAddResponse.self, from: data)
    }

    func removeFromWatchlist(id: String) async throws {
        guard let token = authToken else { throw APIError.unauthorized }
        let request = makeAuthedRequest(path: "/v1/watchlist/\(id)", method: "DELETE", token: token)
        let (data, response) = try await performRequest(request)
        try checkResponse(response, data: data)
    }

    // MARK: - Helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }
    }

    private func makeAuthedRequest(path: String, method: String, token: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "\(Constants.apiBaseURL)\(path)")!)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        return request
    }

    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid server response")
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = try? JSONDecoder().decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(
                errorBody?.error ?? "Server error (\(httpResponse.statusCode))"
            )
        }
    }
}

// MARK: - Thread-safe auth token storage

private final class AuthTokenStore: Sendable {
    private let lock = NSLock()
    private let storage = UnsafeMutablePointer<String?>.allocate(capacity: 1)

    init() {
        storage.initialize(to: nil)
    }

    deinit {
        storage.deinitialize(count: 1)
        storage.deallocate()
    }

    func get() -> String? {
        lock.lock()
        defer { lock.unlock() }
        return storage.pointee
    }

    func set(_ token: String?) {
        lock.lock()
        defer { lock.unlock() }
        storage.pointee = token
    }
}

// MARK: - Watchlist Response Models

struct WatchlistResponse: Codable, Sendable {
    let items: [WatchlistItem]
    let count: Int
}

struct WatchlistItem: Codable, Sendable, Identifiable {
    let id: String
    let productName: String
    let query: String
    let sourceUrl: String?
    let targetPrice: Int?
    let notifyOnDrop: Bool?
    let createdAt: String
    let verdict: WatchlistVerdict?
}

struct WatchlistVerdict: Codable, Sendable {
    let verdict: String
    let confidence: Double?
    let shortReason: String?
    let bestPrice: Int?
    let bestRetailer: String?
    let generatedAt: String?

    var verdictType: VerdictType {
        VerdictType(rawValue: verdict) ?? .wait
    }
}

struct WatchlistAddResponse: Codable, Sendable {
    let item: WatchlistAddItem
}

struct WatchlistAddItem: Codable, Sendable {
    let id: String
}
