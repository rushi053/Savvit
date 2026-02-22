import SwiftUI
import PostHog

@main
struct SavvitApp: App {
    init() {
        let config = PostHogConfig(
            apiKey: "phc_yoky9EHtF40JzsJD2AO5kxDtEIxEB97ovKNGEW83gI7",
            host: "https://us.i.posthog.com"
        )
        config.captureScreenViews = true
        config.captureApplicationLifecycleEvents = true
        PostHogSDK.shared.setup(config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
