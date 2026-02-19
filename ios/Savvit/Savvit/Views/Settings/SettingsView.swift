import SwiftUI

struct SettingsView: View {
    @AppStorage("pushNotifications") private var pushNotifications = true
    @AppStorage("priceAlerts") private var priceAlerts = true
    @AppStorage("darkMode") private var darkMode = false

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

                    profileCard
                        .padding(.bottom, Theme.spacingXL)

                    proUpgradeCard
                        .padding(.bottom, 28)

                    sectionHeader("PREFERENCES")

                    VStack(spacing: 0) {
                        settingToggle(icon: "bell.fill", label: "Push Notifications", isOn: $pushNotifications)
                        sectionDivider
                        settingToggle(
                            icon: "bell.badge.fill",
                            label: "Price Drop Alerts",
                            subtitle: "Get notified when tracked prices drop",
                            isOn: $priceAlerts
                        )
                        sectionDivider
                        settingToggle(icon: "moon.fill", label: "Dark Mode", isOn: $darkMode)
                        sectionDivider
                        settingValue(icon: "globe", label: "Region", value: "United States")
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
                        settingNav(icon: "questionmark.circle.fill", label: "Help Center")
                        sectionDivider
                        settingNav(icon: "message.fill", label: "Send Feedback")
                        sectionDivider
                        settingNav(icon: "star.fill", label: "Rate Savvit")
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
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: Theme.spacingLG) {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .fill(Theme.savvitBlue)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(Theme.textOnBlue)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text("Alex")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("alex@example.com")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 20))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Theme.spacingXL)
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
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

            Button {} label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("$4.99/month")
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

    private var settingIcon: some View {
        EmptyView()
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

    private func settingNav(icon: String, label: String) -> some View {
        HStack(spacing: Theme.spacingMD) {
            iconBadge(icon)

            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 18))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(.horizontal, Theme.spacingLG)
        .padding(.vertical, 14)
    }
}

#Preview {
    SettingsView()
}
