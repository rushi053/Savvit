import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var watchlistVM = WatchlistViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
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
        .environment(watchlistVM)
    }
}

// MARK: - Placeholder (Phase 4)

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
