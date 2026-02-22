import SwiftUI
import StoreKit

struct SettingsView: View {
    @State private var showNotificationsComingSoon = false
    @AppStorage("darkMode") private var darkMode = false
    @AppStorage("selectedRegion") private var selectedRegion = ""
    @State private var showProComingSoon = false

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

                    proUpgradeCard
                        .padding(.bottom, 28)

                    sectionHeader("PREFERENCES")

                    VStack(spacing: 0) {
                        Button { showNotificationsComingSoon = true } label: {
                            settingNav(icon: "bell.fill", label: "Notifications", trailing: "Coming with Pro")
                        }
                        .buttonStyle(.plain)
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
                        Text("Savvit v1.0.0")
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
        }
    }

    // MARK: - Pro Upgrade

    private var proUpgradeCard: some View {
        VStack(spacing: Theme.spacingLG) {
            HStack(spacing: Theme.spacingMD) {
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .fill(Theme.savvitLime.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "crown.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Theme.savvitLime)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Upgrade to Pro")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("AI predictions, unlimited searches & more")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Button {
                Analytics.track("pro_tapped", properties: ["context": "settings"])
                showProComingSoon = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text(settingsProPrice)
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textOnLime)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Theme.savvitLime)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            }
        }
        .padding(Theme.spacingXL)
        .background(
            LinearGradient(
                colors: [Color(hex: "1C1C1E"), Color(hex: "2C2C2E")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .alert("Coming Soon", isPresented: $showProComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Savvit Pro is coming soon! We'll notify you when it's ready.")
        }
        .alert("Coming Soon", isPresented: $showNotificationsComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Push notifications and price drop alerts are coming with Savvit Pro.")
        }
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

    private var settingsProPrice: String {
        let region = selectedRegion.isEmpty
            ? (Locale.current.region?.identifier ?? "US")
            : selectedRegion
        return region == "IN" ? "₹79/mo" : "$4.99/mo"
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

#Preview {
    SettingsView()
}
