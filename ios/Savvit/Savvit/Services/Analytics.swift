import PostHog

enum Analytics {
    static func track(_ event: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.capture(event, properties: properties)
    }

    static func identify(userId: String, properties: [String: Any]? = nil) {
        PostHogSDK.shared.identify(userId, userProperties: properties)
    }
}
