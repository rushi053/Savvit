import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(WatchlistViewModel.self) private var watchlist
    @State private var itemToDelete: LocalWatchlistItem?
    @AppStorage("watchlistBannerDismissed") private var bannerDismissed = false
    @State private var showPaywall = false
    @State private var alertsEnabled = AlertsManager.alertsEnabled
    private var pro = ProManager.shared

    init(selectedTab: Binding<Int>) {
        _selectedTab = selectedTab
    }

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

                    if watchlist.isRefreshing {
                        HStack(spacing: 6) {
                            ProgressView()
                                .controlSize(.mini)
                            Text("Checking latest prices…")
                        }
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textTertiary)
                    } else if let refreshed = watchlist.lastRefreshAt {
                        Text("Prices checked \(refreshed, format: .relative(presentation: .named))")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
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

                if showAlertsBanner {
                    alertsBanner
                        .padding(.bottom, Theme.spacingMD)
                }

                VStack(spacing: Theme.spacingMD) {
                    ForEach(watchlist.displayItems) { item in
                        WatchlistCard(item: item)
                            .contextMenu {
                                Button(role: .destructive) {
                                    itemToDelete = item
                                } label: {
                                    Label("Remove from Watchlist", systemImage: "trash")
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 120)
        }
        .refreshable {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            await watchlist.refreshPrices(force: true)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(context: "watchlist_banner")
        }
        .alert("Remove from Watchlist?", isPresented: .init(
            get: { itemToDelete != nil },
            set: { if !$0 { itemToDelete = nil } }
        )) {
            Button("Remove", role: .destructive) {
                if let item = itemToDelete {
                    withAnimation(Theme.snappy) { watchlist.removeItem(id: item.id) }
                }
                itemToDelete = nil
            }
            Button("Cancel", role: .cancel) { itemToDelete = nil }
        } message: {
            Text("This will stop tracking \"\(itemToDelete?.productName ?? "")\".")
        }
    }

    // MARK: - Alerts Banner

    private var showAlertsBanner: Bool {
        if pro.isPro {
            return !alertsEnabled // Pro but alerts off → offer to enable
        }
        return !bannerDismissed // Free → pitch Pro (dismissible)
    }

    private var alertsBanner: some View {
        HStack(alignment: .top, spacing: Theme.spacingMD) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.savvitLime)
                .frame(width: 32, height: 32)
                .background(Theme.savvitBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("Price-Drop Alerts")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                Text(pro.isPro
                     ? "Turn on notifications and we'll watch these prices for you."
                     : "Get notified when prices drop on your saved items — with Savvit Pro.")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    if pro.isPro {
                        Task {
                            if await AlertsManager.requestPermission() {
                                AlertsManager.alertsEnabled = true
                                withAnimation(Theme.snappy) { alertsEnabled = true }
                                AlertsManager.scheduleBackgroundRefresh()
                                Analytics.track("alerts_enabled", properties: ["context": "banner"])
                            }
                        }
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Text(pro.isPro ? "Enable Alerts" : "Unlock with Pro")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textOnLime)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Theme.savvitLime)
                        .clipShape(Capsule())
                }
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            if !pro.isPro {
                Button {
                    withAnimation(Theme.snappy) { bannerDismissed = true }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(width: 24, height: 24)
                }
            }
        }
        .padding(Theme.spacingLG)
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
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
