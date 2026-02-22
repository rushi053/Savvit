import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("darkMode") private var darkMode = false
    @State private var selectedTab = 0
    @State private var watchlistVM = WatchlistViewModel()
    @Namespace private var tabAnimation

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                SearchView()
                    .tag(0)

                HomeView(selectedTab: $selectedTab)
                    .tag(1)

                SettingsView()
                    .tag(2)
            }

            tabBar
        }
        .preferredColorScheme(darkMode ? .dark : .light)
        .environment(watchlistVM)
        .fullScreenCover(isPresented: .init(
            get: { !hasSeenOnboarding },
            set: { if $0 { hasSeenOnboarding = false } }
        )) {
            OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
        }
    }

    // MARK: - Custom Floating Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: selectedTab == index ? .semibold : .regular))

                        Text(tab.label)
                            .font(.system(size: 10, weight: selectedTab == index ? .semibold : .medium))
                    }
                    .foregroundStyle(selectedTab == index ? Theme.savvitLime : Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selectedTab == index {
                            Capsule()
                                .fill(Theme.savvitBlue)
                                .matchedGeometryEffect(id: "tabPill", in: tabAnimation)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 15, y: 2)
                .shadow(color: .black.opacity(0.03), radius: 1, y: 0)
        )
        .padding(.horizontal, Theme.spacingXL)
        .padding(.bottom, 4)
    }

    private let tabs: [(icon: String, label: String)] = [
        ("magnifyingglass", "Search"),
        ("eye", "Watchlist"),
        ("gearshape", "Settings"),
    ]
}

#Preview {
    ContentView()
}
