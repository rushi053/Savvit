import SwiftUI

enum Theme {

    // MARK: - Brand Colors

    static let savvitPrimary = Color(hex: "#6C5CE7")
    static let savvitSecondary = Color(hex: "#A29BFE")

    // MARK: - Verdict Colors

    static let verdictBuy = Color(hex: "#00B894")
    static let verdictWait = Color(hex: "#FDCB6E")
    static let verdictDont = Color(hex: "#E17055")

    // MARK: - Dark Mode Backgrounds

    static let bgPrimary = Color(hex: "#0A0A0F")
    static let bgSecondary = Color(hex: "#14141F")
    static let bgTertiary = Color(hex: "#1E1E2E")

    // MARK: - Dark Mode Text

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#A0A0B0")
    static let textTertiary = Color(hex: "#6B6B80")

    // MARK: - Light Mode (reserved for Phase 4)

    static let bgPrimaryLight = Color(hex: "#F8F8FC")
    static let bgSecondaryLight = Color.white
    static let bgTertiaryLight = Color(hex: "#F0F0F5")
    static let textPrimaryLight = Color(hex: "#1A1A2E")
    static let textSecondaryLight = Color(hex: "#6B6B80")

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 20
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32

    // MARK: - Corner Radius

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16

    // MARK: - Typography

    static let heroTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 24, weight: .bold)
    static let cardTitle = Font.system(size: 17, weight: .semibold)
    static let bodyText = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .medium)
    static let finePrint = Font.system(size: 11, weight: .regular)
}
