import SwiftUI

struct HomeView: View {
    @Environment(WatchlistViewModel.self) private var watchlist
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                if watchlist.displayItems.isEmpty {
                    emptyState
                } else {
                    watchlistContent
                }
            }
            .navigationTitle("Savvit")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Theme.spacingLG) {
            Spacer()

            Image(systemName: "bag")
                .font(.system(size: 64, weight: .ultraLight))
                .foregroundStyle(Theme.textTertiary)

            VStack(spacing: Theme.spacingSM) {
                Text("Your watchlist is empty")
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.textPrimary)

                Text("Search for a product to get\nyour first AI verdict")
                    .font(Theme.bodyText)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
    }

    // MARK: - Watchlist Content

    private var watchlistContent: some View {
        ScrollView {
            LazyVStack(spacing: Theme.spacingMD) {
                ForEach(Array(watchlist.displayItems.enumerated()), id: \.element.id) { index, item in
                    WatchlistCard(item: item)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.05),
                            value: watchlist.displayItems.count
                        )
                }

                if !watchlist.isAtFreeLimit {
                    addItemHint
                } else {
                    freeLimit
                }
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingSM)
            .padding(.bottom, 40)
        }
    }

    private var addItemHint: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 16))
            Text("\(watchlist.itemCount)/\(Constants.freeWatchlistLimit) items · Search to add more")
                .font(Theme.caption)
        }
        .foregroundStyle(Theme.textTertiary)
        .padding(.top, Theme.spacingSM)
    }

    private var freeLimit: some View {
        VStack(spacing: Theme.spacingSM) {
            Text("Free limit reached (\(Constants.freeWatchlistLimit)/\(Constants.freeWatchlistLimit))")
                .font(Theme.caption)
                .foregroundStyle(Theme.textTertiary)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                // TODO: Show Pro upgrade
            } label: {
                Text("Upgrade to Pro for unlimited")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.savvitPrimary)
            }
        }
        .padding(.top, Theme.spacingSM)
    }
}
