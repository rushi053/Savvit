import SwiftUI

enum Theme {

    // MARK: - Adaptive Colors

    private static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }

    // Backgrounds
    static let bgPrimary = adaptive(light: "FFFFFF", dark: "0A0A0A")
    static let bgSecondary = adaptive(light: "F5F5F7", dark: "1C1C1E")
    static let bgTertiary = adaptive(light: "E5E5EA", dark: "2C2C2E")

    // Brand Accent — swaps in dark mode so lime leads on dark backgrounds
    static let savvitBlue = adaptive(light: "233DFF", dark: "C5FF00")
    static let savvitLime = adaptive(light: "C5FF00", dark: "233DFF")
    static let textOnLime = adaptive(light: "1C1C1E", dark: "FFFFFF")


    // Verdict
    static let verdictBuy = Color(hex: "34C759")
    static let verdictWait = Color(hex: "FF9500")
    static let verdictDont = Color(hex: "FF3B30")

    // Verdict Card Backgrounds
    static let verdictBuyBg = adaptive(light: "ECFDF5", dark: "0D2818")
    static let verdictWaitBg = adaptive(light: "FFFBEB", dark: "2D1A00")
    static let verdictDontBg = adaptive(light: "FEF2F2", dark: "2D0A0A")

    // Verdict Text
    static let verdictBuyText = Color(hex: "1B8031")
    static let verdictWaitText = Color(hex: "CC7700")
    static let verdictDontText = Color(hex: "CC1A1A")

    // Text
    static let textPrimary = adaptive(light: "1C1C1E", dark: "FFFFFF")
    static let textSecondary = adaptive(light: "8E8E93", dark: "8E8E93")
    static let textTertiary = adaptive(light: "C7C7CC", dark: "48484A")

    static let textOnBlue = adaptive(light: "FFFFFF", dark: "1C1C1E")

    // Danger
    static let danger = Color(hex: "FF3B30")

    // MARK: - Typography (SF Pro)

    static let heroText = Font.system(size: 28, weight: .bold)
    static let title1 = Font.system(size: 22, weight: .bold)
    static let title2 = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let bodyEmphasis = Font.system(size: 15, weight: .semibold)
    static let caption = Font.system(size: 14, weight: .regular)
    static let footnote = Font.system(size: 13, weight: .regular)
    static let small = Font.system(size: 12, weight: .semibold)

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24

    // MARK: - Layout

    static let cornerRadius: CGFloat = 24
    static let cornerRadiusMD: CGFloat = 16
    static let cornerRadiusSM: CGFloat = 12
    static let inputHeight: CGFloat = 52
    static let buttonHeight: CGFloat = 50
    static let horizontalPadding: CGFloat = 20

    // MARK: - Animations

    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let gentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
}
