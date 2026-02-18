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

class APIClient {
    static let shared = APIClient()

    private var authToken: String?

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    func searchProduct(query: String) async throws -> ProductSearchResult {
        guard let url = URL(string: "\(Constants.apiBaseURL)/v1/products/search") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120
        request.httpBody = try JSONEncoder().encode(["query": query])

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error.localizedDescription)
        }

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
}
