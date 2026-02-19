import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(WatchlistViewModel.self) private var watchlist

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
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("SavvitLogo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                .shadow(color: Theme.savvitBlue.opacity(0.15), radius: 10, y: 4)

            Text("Your watchlist is empty")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .tracking(-0.3)
                .padding(.top, Theme.spacingXL)

            Text("Search for a product and add it\nto track prices and deals")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, Theme.spacingSM)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(Theme.snappy) { selectedTab = 0 }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15))
                    Text("Start Searching")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textOnBlue)
                .padding(.horizontal, 32)
                .frame(height: Theme.buttonHeight)
                .background(Theme.savvitBlue)
                .clipShape(Capsule())
            }
            .padding(.top, Theme.spacingXXL)

            Spacer()
        }
    }

    // MARK: - Watchlist Content

    private var watchlistContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.savvitBlue)
                        Text("Watchlist")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .tracking(-0.5)
                    }

                    Text("\(watchlist.itemCount) product\(watchlist.itemCount != 1 ? "s" : "") tracked")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.top, 60)
                .padding(.bottom, Theme.spacingXL)

                HStack(spacing: Theme.spacingMD) {
                    statCard(
                        icon: "eye",
                        label: "Tracking",
                        count: watchlist.itemCount,
                        isPrimary: true
                    )
                    statCard(
                        icon: "checkmark.circle",
                        label: "Ready to Buy",
                        count: watchlist.displayItems.filter { $0.verdictType == .buyNow }.count,
                        isPrimary: false
                    )
                }
                .padding(.bottom, Theme.spacingXL)

                VStack(spacing: Theme.spacingMD) {
                    ForEach(watchlist.displayItems) { item in
                        WatchlistCard(item: item)
                    }
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 120)
        }
    }

    // MARK: - Stat Card

    private func statCard(icon: String, label: String, count: Int, isPrimary: Bool) -> some View {
        VStack(alignment: .leading, spacing: Theme.spacingSM) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(isPrimary ? Theme.savvitLime : Theme.textOnLime)
                    .frame(width: 24, height: 24)
                    .background(isPrimary ? Theme.savvitBlue : Theme.savvitLime)
                    .clipShape(Circle())

                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }

            Text("\(count)")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.spacingLG)
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Theme.savvitBlue.opacity(0.12), lineWidth: 1)
        )
    }
}
