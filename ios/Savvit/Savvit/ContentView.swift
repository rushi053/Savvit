import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabPlaceholder()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            SettingsTabPlaceholder()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Theme.savvitPrimary)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Placeholder Tabs (Phase 3 & 4)

private struct HomeTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                VStack(spacing: Theme.spacingLG) {
                    Image(systemName: "bag")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(Theme.textTertiary)

                    Text("Your watchlist is empty")
                        .font(Theme.cardTitle)
                        .foregroundStyle(Theme.textPrimary)

                    Text("Search for a product to get\nyour first AI verdict")
                        .font(Theme.bodyText)
                        .foregroundStyle(Theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .navigationTitle("Savvit")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

private struct SettingsTabPlaceholder: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                VStack(spacing: Theme.spacingMD) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(Theme.textTertiary)

                    Text("Settings coming soon")
                        .font(Theme.bodyText)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview {
    ContentView()
}
