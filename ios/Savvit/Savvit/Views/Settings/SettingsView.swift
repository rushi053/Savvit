import SwiftUI
import SafariServices
import StoreKit

struct SettingsView: View {
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("selectedRegion") private var selectedRegion = ""
    @State private var showPrivacyPolicy = false
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false
    @State private var showRestoreResult = false
    @State private var alertsEnabled = AlertsManager.alertsEnabled
    private var pro = ProManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(-0.5)
                        .padding(.top, 60)
                        .padding(.bottom, Theme.spacingXXL)

                    sectionHeader("SAVVIT PRO")

                    VStack(spacing: 0) {
                        if pro.isPro {
                            settingValue(icon: "crown.fill", label: "Savvit Pro", value: "Active")
                            sectionDivider
                            Button { showManageSubscriptions = true } label: {
                                settingNav(icon: "creditcard.fill", label: "Manage Subscription")
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button { showPaywall = true } label: {
                                settingNav(icon: "crown.fill", label: "Upgrade to Pro", trailing: "Alerts & unlimited tracking")
                            }
                            .buttonStyle(.plain)
                            sectionDivider
                            Button {
                                Task {
                                    await pro.restorePurchases()
                                    showRestoreResult = true
                                }
                            } label: {
                                settingNav(icon: "arrow.clockwise", label: "Restore Purchases")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Theme.bgPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.bottom, 28)

                    sectionHeader("PREFERENCES")

                    VStack(spacing: 0) {
                        if pro.isPro {
                            settingToggle(
                                icon: "bell.fill",
                                label: "Price-Drop Alerts",
                                subtitle: "Notify me when watched prices fall",
                                isOn: alertsToggleBinding
                            )
                        } else {
                            Button { showPaywall = true } label: {
                                settingNav(icon: "bell.fill", label: "Price-Drop Alerts", trailing: "Pro")
                            }
                            .buttonStyle(.plain)
                        }
                        sectionDivider
                        settingToggle(icon: "moon.fill", label: "Dark Mode", isOn: $darkMode)
                        sectionDivider
                        NavigationLink {
                            RegionPickerView()
                        } label: {
                            settingNav(icon: "globe", label: "Region", trailing: regionDisplayName)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Theme.bgPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.bottom, 28)

                    sectionHeader("SUPPORT")

                    VStack(spacing: 0) {
                        Button { showPrivacyPolicy = true } label: {
                            settingNav(icon: "lock.fill", label: "Privacy Policy")
                        }
                        .buttonStyle(.plain)
                        sectionDivider
                        NavigationLink {
                            HelpCenterView()
                        } label: {
                            settingNav(icon: "questionmark.circle.fill", label: "Help Center")
                        }
                        .buttonStyle(.plain)
                        sectionDivider
                        Button { sendFeedback() } label: {
                            settingNav(icon: "message.fill", label: "Send Feedback")
                        }
                        .buttonStyle(.plain)
                        sectionDivider
                        Button { rateApp() } label: {
                            settingNav(icon: "star.fill", label: "Rate Savvit")
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Theme.bgPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .padding(.bottom, Theme.spacingXXL)

                    VStack(spacing: 2) {
                        Text("Savvit v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.system(size: 12))
                        Text("Made with care for smart shoppers")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.bottom, 100)
            }
            .background(Theme.bgPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: selectedRegion) { _, newRegion in
                Analytics.track("region_changed", properties: ["region": newRegion.isEmpty ? "auto" : newRegion])
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                SafariView(url: URL(string: "https://savvit.app/privacy")!)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(context: "settings")
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .alert("Restore Purchases", isPresented: $showRestoreResult) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(pro.isPro
                     ? "Your Savvit Pro subscription has been restored."
                     : "No active subscription found for this Apple ID.")
            }
        }
    }

    // MARK: - Alerts toggle

    private var alertsToggleBinding: Binding<Bool> {
        Binding(
            get: { alertsEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let granted = await AlertsManager.requestPermission()
                        AlertsManager.alertsEnabled = granted
                        alertsEnabled = granted
                        if granted {
                            AlertsManager.scheduleBackgroundRefresh()
                            Analytics.track("alerts_enabled", properties: ["context": "settings"])
                        }
                    }
                } else {
                    AlertsManager.alertsEnabled = false
                    alertsEnabled = false
                    Analytics.track("alerts_disabled")
                }
            }
        )
    }

    // MARK: - Section Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Theme.textSecondary)
            .tracking(1)
            .padding(.leading, 4)
            .padding(.bottom, Theme.spacingSM)
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.leading, 52)
    }

    private func iconBadge(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 14))
            .foregroundStyle(Theme.savvitLime)
            .frame(width: 32, height: 32)
            .background(Theme.savvitBlue)
            .clipShape(Circle())
    }

    private func settingToggle(
        icon: String, label: String, subtitle: String? = nil, isOn: Binding<Bool>
    ) -> some View {
        HStack(spacing: Theme.spacingMD) {
            iconBadge(icon)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Theme.savvitBlue)
        }
        .padding(.horizontal, Theme.spacingLG)
        .padding(.vertical, 14)
    }

    private func settingValue(icon: String, label: String, value: String) -> some View {
        HStack(spacing: Theme.spacingMD) {
            iconBadge(icon)

            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.spacingLG)
        .padding(.vertical, 14)
    }

    private func settingNav(icon: String, label: String, trailing: String? = nil) -> some View {
        HStack(spacing: Theme.spacingMD) {
            iconBadge(icon)

            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            if let trailing {
                Text(trailing)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 18))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, Theme.spacingLG)
        .padding(.vertical, 14)
    }

    private var regionDisplayName: String {
        let map = ["US": "United States", "IN": "India", "GB": "United Kingdom",
                    "DE": "Germany", "CA": "Canada", "AU": "Australia",
                    "JP": "Japan", "FR": "France"]
        if selectedRegion.isEmpty { return "Auto" }
        return map[selectedRegion] ?? selectedRegion
    }

    // MARK: - Actions

    private func sendFeedback() {
        Analytics.track("feedback_tapped")
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let device = UIDevice.current.model
        let systemVersion = UIDevice.current.systemVersion
        let deviceInfo = "\(device), iOS \(systemVersion)"
        let subject = "Savvit Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Savvit%20Feedback"
        let body = "App Version: \(appVersion)\nDevice: \(deviceInfo)\n\n".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:feedback@savvit.app?subject=\(subject)&body=\(body)") {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        Analytics.track("rate_app_tapped")
        if let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

#Preview {
    SettingsView()
}
