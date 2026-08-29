import SwiftUI
import PostHog
import BackgroundTasks

@main
struct SavvitApp: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let config = PostHogConfig(
            apiKey: "phc_yoky9EHtF40JzsJD2AO5kxDtEIxEB97ovKNGEW83gI7",
            host: "https://us.i.posthog.com"
        )
        config.captureScreenViews = true
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)

        Self.registerBackgroundRefresh()

        // Wake the Render backend so the first search doesn't eat the
        // free-tier cold start.
        APIClient.shared.prewarm()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                APIClient.shared.prewarm()
                Task { await ProManager.shared.refreshEntitlements() }
                Task { await WatchlistViewModel.shared.refreshIfStale() }
            case .background:
                AlertsManager.scheduleBackgroundRefresh()
            default:
                break
            }
        }
    }

    // MARK: - Background watchlist refresh (price-drop alerts)

    private static func registerBackgroundRefresh() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Constants.bgRefreshTaskID,
            using: nil
        ) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            // Always keep the chain alive for next time
            AlertsManager.scheduleBackgroundRefresh()

            let work = Task { @MainActor in
                // Task completion is guaranteed exactly once: cancellation
                // makes refreshPrices bail early and we still land here.
                defer { refreshTask.setTaskCompleted(success: true) }

                // Alerts are a Pro feature
                guard ProManager.shared.isPro, AlertsManager.alertsEnabled else { return }

                let watchlist = WatchlistViewModel.shared
                let drops = await watchlist.refreshPrices()
                await AlertsManager.notify(drops: drops, currencySymbol: watchlist.regionCurrencySymbol)
            }

            refreshTask.expirationHandler = {
                work.cancel()
            }
        }
    }
}
