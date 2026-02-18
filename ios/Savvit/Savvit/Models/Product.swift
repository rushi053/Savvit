import Foundation

// MARK: - Verdict Type

enum VerdictType: String, Codable, Sendable {
    case buyNow = "BUY_NOW"
    case wait = "WAIT"
    case dontBuy = "DONT_BUY"

    var icon: String {
        switch self {
        case .buyNow: "checkmark.circle.fill"
        case .wait: "clock.fill"
        case .dontBuy: "xmark.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .buyNow: "BUY NOW"
        case .wait: "WAIT"
        case .dontBuy: "DON'T BUY"
        }
    }
}

// MARK: - Product Search Result

struct ProductSearchResult: Codable, Sendable {
    let query: String
    let product: String
    let verdict: String
    let confidence: Double
    let shortReason: String
    let reason: String
    let bestPrice: PriceInfo?
    let prices: [PriceInfo]
    let proAnalysis: ProAnalysis?
    let launchIntel: LaunchIntel?
    let nextSale: SaleEvent?
    let priceHistory: [PricePoint]?
    let citations: [String]?

    var verdictType: VerdictType {
        VerdictType(rawValue: verdict) ?? .wait
    }
}

// MARK: - Price Info

struct PriceInfo: Codable, Sendable {
    let retailer: String
    let price: Int
    let currency: String?
    let url: String?
    let offers: String?
    let inStock: Bool?
}

// MARK: - Pro Analysis

struct ProAnalysis: Codable, Sendable {
    let bestCurrentDeal: String?
    let waitReason: String?
    let estimatedSavings: String?
    let bestTimeToBuy: String?
    let launchAlert: String?
}

// MARK: - Launch Intelligence

struct LaunchIntel: Codable, Sendable {
    let upcomingProduct: String?
    let expectedDate: String?
    let summary: String?
}

// MARK: - Sale Event

struct SaleEvent: Codable, Sendable {
    let name: String
    let month: Int?
    let discount: String?
}

// MARK: - Price History Point

struct PricePoint: Codable, Sendable {
    let date: String
    let price: Int
}
