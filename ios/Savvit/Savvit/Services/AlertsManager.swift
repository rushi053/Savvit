import Foundation
import BackgroundTasks
import UserNotifications

/// Price-drop alerts: local notifications fired when a background (or
/// foreground) watchlist refresh finds a lower price or a verdict flipping
/// to BUY_NOW. No server push infrastructure — BGAppRefresh + local
/// notifications only.
enum AlertsManager {

    static var alertsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.alertsEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.UserDefaultsKeys.alertsEnabled) }
    }

    // MARK: - Permission

    /// Returns true if notifications are authorized (requests if undetermined).
    static func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        default:
            return false
        }
    }

    static func hasPermission() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return true
        default: return false
        }
    }

    // MARK: - Notifications

    static func notify(drops: [PriceDrop], currencySymbol: String) async {
        guard alertsEnabled, await hasPermission() else { return }

        for drop in drops.prefix(3) {
            let content = UNMutableNotificationContent()
            content.sound = .default

            switch drop.kind {
            case .priceDrop(let oldPrice, let newPrice):
                let saved = oldPrice - newPrice
                content.title = "Price drop: \(drop.productName)"
                content.body = "Now \(currencySymbol)\(newPrice.formattedWithSeparator) — down \(currencySymbol)\(saved.formattedWithSeparator) from \(currencySymbol)\(oldPrice.formattedWithSeparator)."
            case .verdictFlippedToBuy:
                content.title = "Time to buy: \(drop.productName)"
                content.body = "Savvit's verdict just changed to Buy Now. Check the latest prices."
            }

            let request = UNNotificationRequest(
                identifier: "price-alert-\(drop.itemID)",
                content: content,
                trigger: nil // deliver immediately
            )
            try? await UNUserNotificationCenter.current().add(request)
        }

        Analytics.track("price_alert_fired", properties: ["count": drops.count])
    }

    // MARK: - Background refresh scheduling

    static func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.bgRefreshTaskID)
        request.earliestBeginDate = Date(timeIntervalSinceNow: Constants.refreshStaleness)
        // Submitting again replaces the pending request; errors here are
        // non-fatal (e.g. running in a simulator or Low Power Mode).
        try? BGTaskScheduler.shared.submit(request)
    }
}

// MARK: - Price drop model

struct PriceDrop: Sendable {
    enum Kind: Sendable {
        case priceDrop(oldPrice: Int, newPrice: Int)
        case verdictFlippedToBuy
    }

    let itemID: String
    let productName: String
    let kind: Kind
}

private extension Int {
    var formattedWithSeparator: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
