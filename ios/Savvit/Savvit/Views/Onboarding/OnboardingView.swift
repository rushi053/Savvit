import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0
    @State private var selectedRegion: String

    private let regions: [(code: String, flag: String, name: String, currency: String)] = [
        ("US", "🇺🇸", "United States", "$"),
        ("IN", "🇮🇳", "India", "₹"),
        ("GB", "🇬🇧", "United Kingdom", "£"),
        ("DE", "🇩🇪", "Germany", "€"),
        ("CA", "🇨🇦", "Canada", "CA$"),
        ("AU", "🇦🇺", "Australia", "A$"),
        ("JP", "🇯🇵", "Japan", "¥"),
        ("FR", "🇫🇷", "France", "€"),
    ]

    init(hasSeenOnboarding: Binding<Bool>) {
        _hasSeenOnboarding = hasSeenOnboarding
        let deviceRegion = Locale.current.region?.identifier ?? "US"
        let supported = ["US", "IN", "GB", "DE", "CA", "AU", "JP", "FR"]
        _selectedRegion = State(initialValue: supported.contains(deviceRegion) ? deviceRegion : "US")
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                page1.tag(0)
                page2.tag(1)
                page3.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)

            VStack(spacing: Theme.spacingXL) {
                dots
                actionButton
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 44)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
    }

    // MARK: - Page 1

    private var page1: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 60)

            Image("SavvitLogo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Theme.savvitBlue.opacity(0.25), radius: 16, y: 4)

            Spacer()

            VStack(spacing: Theme.spacingMD) {
                Text("Never Google\n'should I buy' again.")
                    .font(.system(size: 30, weight: .heavy))
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textPrimary)

                Text("Get an instant AI verdict with real-time\nprices and sale predictions.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, Theme.horizontalPadding)

            Spacer().frame(height: 36)

            HStack(spacing: 10) {
                verdictPill("BUY NOW", color: Theme.verdictBuy, icon: "checkmark.circle.fill")
                verdictPill("WAIT", color: Theme.verdictWait, icon: "clock.fill")
                verdictPill("DON'T BUY", color: Theme.verdictDont, icon: "xmark.circle.fill")
            }

            Spacer()
            Spacer()
        }
    }

    // MARK: - Page 2

    private var page2: some View {
        OnboardingPageView(
            title: "Search. Verdict. Done.",
            subtitle: "We check prices, sales, and launches\nacross retailers — then give you the answer."
        ) {
            stepsCard
                .padding(.horizontal, Theme.horizontalPadding)
        }
    }

    // MARK: - Page 3

    private var page3: some View {
        OnboardingPageView(
            title: "Prices where you are.",
            subtitle: "Pick your market for accurate results."
        ) {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                spacing: 10
            ) {
                ForEach(regions, id: \.code) { region in
                    regionCard(region)
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
        }
    }

    // MARK: - Steps Card (Page 2)

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepRow(icon: "magnifyingglass", text: "Search any product or paste a link")

            connector

            stepRow(icon: "brain.head.profile", text: "AI analyzes prices, sales & launches")

            connector

            stepRow(icon: "checkmark.seal.fill", text: "Get your verdict in seconds")
        }
        .padding(Theme.spacingXL)
        .background(Theme.savvitBlue.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Theme.savvitBlue.opacity(0.1), lineWidth: 1)
        )
    }

    private func stepRow(icon: String, text: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.savvitLime)
                .frame(width: 40, height: 40)
                .background(Theme.savvitBlue)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }

    private var connector: some View {
        Rectangle()
            .fill(Theme.savvitBlue.opacity(0.15))
            .frame(width: 2, height: 20)
            .padding(.leading, 19)
    }

    // MARK: - Components

    private func verdictPill(_ label: String, color: Color, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 13))
            Text(label)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule().fill(color.opacity(0.1))
        )
    }

    private func regionCard(_ region: (code: String, flag: String, name: String, currency: String)) -> some View {
        let isSelected = selectedRegion == region.code
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedRegion = region.code
            }
        } label: {
            HStack(spacing: 8) {
                Text(region.flag)
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 1) {
                    Text(region.name)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(region.currency)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.savvitLime)
                        .frame(width: 20, height: 20)
                        .background(Theme.savvitBlue)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(isSelected ? Theme.savvitBlue.opacity(0.06) : Theme.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                    .stroke(isSelected ? Theme.savvitBlue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Dots

    private var dots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Theme.savvitBlue : Theme.textTertiary)
                    .frame(width: index == currentPage ? 20 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
            }
        }
    }

    // MARK: - Button

    private var actionButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if currentPage < 2 {
                currentPage += 1
            } else {
                UserDefaults.standard.set(selectedRegion, forKey: Constants.UserDefaultsKeys.selectedRegion)
                Analytics.track("onboarding_completed", properties: ["region_selected": selectedRegion])
                hasSeenOnboarding = true
            }
        } label: {
            Text(currentPage < 2 ? "Next" : "Start Searching")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.textOnBlue)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .background(Theme.savvitBlue)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        }
    }
}
