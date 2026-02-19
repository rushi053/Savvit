import SwiftUI

// MARK: - Color Hex Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Hex Init (for adaptive colors)

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Currency Formatting (Indian ₹ format)

extension Int {
    var inrFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: self)) ?? "₹\(self)"
    }
}

extension Double {
    var inrFormatted: String {
        Int(self).inrFormatted
    }
}

// MARK: - VerdictType View Properties

extension VerdictType {
    var color: Color {
        switch self {
        case .buyNow: Theme.verdictBuy
        case .wait: Theme.verdictWait
        case .dontBuy: Theme.verdictDont
        }
    }

    var bgColor: Color {
        switch self {
        case .buyNow: Theme.verdictBuyBg
        case .wait: Theme.verdictWaitBg
        case .dontBuy: Theme.verdictDontBg
        }
    }

    var textColor: Color {
        switch self {
        case .buyNow: Theme.verdictBuyText
        case .wait: Theme.verdictWaitText
        case .dontBuy: Theme.verdictDontText
        }
    }

    var displayLabel: String {
        switch self {
        case .buyNow: "Buy Now"
        case .wait: "Wait to Buy"
        case .dontBuy: "Don't Buy"
        }
    }
}
