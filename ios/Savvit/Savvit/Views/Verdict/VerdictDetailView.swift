import SwiftUI

struct VerdictDetailView: View {
    let result: ProductSearchResult

    @Environment(WatchlistViewModel.self) private var watchlist
    @State private var showVerdict = false
    @State private var showContent = false
    @State private var showProUpgrade = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingLG) {
                verdictHeroSection

                Divider()
                    .background(Theme.bgTertiary)
                    .padding(.horizontal, 8)

                if !result.prices.isEmpty {
                    buyNowSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }

                if result.launchIntel != nil || result.nextSale != nil {
                    waitSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 30)
                }

                if result.proAnalysis != nil {
                    proInsightSection
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 40)
                }

                    if let citations = result.citations, !citations.isEmpty {
                    citationsSection
                        .opacity(showContent ? 1 : 0)
                }

                watchlistButton
                    .opacity(showContent ? 1 : 0)
                    .padding(.top, Theme.spacingSM)
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.bottom, 60)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(result.product)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear(perform: animateEntrance)
    }

    private func animateEntrance() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            showVerdict = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
            showContent = true
        }
    }

    // MARK: - Verdict Hero

    private var verdictHeroSection: some View {
        VStack(spacing: Theme.spacingMD) {
            ZStack {
                Circle()
                    .fill(result.verdictType.color.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .blur(radius: 40)

                VerdictBadge(verdict: result.verdict, size: 44)
            }
            .scaleEffect(showVerdict ? 1.0 : 0.5)
            .opacity(showVerdict ? 1.0 : 0)

            Text("\(Int(result.confidence * 100))% confidence")
                .font(Theme.caption)
                .foregroundStyle(Theme.textSecondary)
                .opacity(showVerdict ? 1 : 0)

            Text(result.shortReason)
                .font(Theme.sectionTitle)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .opacity(showVerdict ? 1 : 0)

            Text(result.reason)
                .font(Theme.bodyText)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 8)
                .opacity(showVerdict ? 1 : 0)
        }
        .padding(.top, Theme.spacingLG)
    }

    // MARK: - Buy Now Section

    private var buyNowSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            sectionHeader(icon: "mappin.circle.fill", title: "IF YOU BUY NOW")

            VStack(spacing: 0) {
                ForEach(Array(result.prices.enumerated()), id: \.offset) { index, price in
                    priceRow(price: price, isBest: index == 0)

                    if index < result.prices.count - 1 {
                        Divider()
                            .background(Theme.bgTertiary)
                            .padding(.horizontal, Theme.spacingMD)
                    }
                }
            }
            .background(Theme.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG))

            if let bestPrice = result.bestPrice,
               let urlString = bestPrice.url,
               let buyURL = URL(string: urlString) {
                Link(destination: buyURL) {
                    HStack(spacing: 8) {
                        Image(systemName: "cart.fill")
                        Text("Buy on \(bestPrice.retailer)")
                            .fontWeight(.semibold)
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.savvitPrimary.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD))
                }
            }
        }
    }

    private func priceRow(price: PriceInfo, isBest: Bool) -> some View {
        HStack(spacing: 12) {
            if isBest {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.verdictBuy)
                    .font(.system(size: 18))
            } else {
                Circle()
                    .fill(Theme.bgTertiary)
                    .frame(width: 18, height: 18)
            }

            Text(price.retailer)
                .font(isBest ? .system(size: 15, weight: .semibold) : Theme.bodyText)
                .foregroundStyle(Theme.textPrimary)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(price.price.inrFormatted)
                    .font(isBest
                        ? .system(size: 17, weight: .bold)
                        : .system(size: 15, weight: .medium))
                    .foregroundStyle(isBest ? Theme.textPrimary : Theme.textSecondary)

                if let offers = price.offers, !offers.isEmpty {
                    Text(offers)
                        .font(Theme.finePrint)
                        .foregroundStyle(Theme.savvitSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .padding(.horizontal, Theme.spacingMD)
        .padding(.vertical, 14)
        .background(isBest ? Theme.bgTertiary.opacity(0.3) : .clear)
    }

    // MARK: - Wait Section

    private var waitSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            sectionHeader(icon: "hourglass", title: "IF YOU CAN WAIT")

            if let intel = result.launchIntel {
                launchIntelCard(intel: intel)
            }

            if let sale = result.nextSale {
                saleEventCard(sale: sale)
            }
        }
    }

    private func launchIntelCard(intel: LaunchIntel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .foregroundStyle(Theme.savvitPrimary)
                    .font(.system(size: 18))
                Text(intel.upcomingProduct ?? "New Product")
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.textPrimary)
            }

            if let date = intel.expectedDate {
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text("Expected \(date)")
                }
                .font(Theme.bodyText)
                .foregroundStyle(Theme.textSecondary)
            }

            if let summary = intel.summary {
                Text(summary)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textTertiary)
                    .lineSpacing(2)
            }

            if let savings = result.proAnalysis?.estimatedSavings {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(Theme.verdictBuy)
                    Text("Potential savings: \(savings)")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.verdictBuy)
                }
                .padding(.top, 4)
            }
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLG)
                .stroke(Theme.savvitPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    private func saleEventCard(sale: SaleEvent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .foregroundStyle(Theme.verdictWait)
                    .font(.system(size: 18))
                Text(sale.name)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.textPrimary)
            }

            if let month = sale.month, (1...12).contains(month) {
                let monthName = Calendar.current.monthSymbols[month - 1]
                let year = Calendar.current.component(.year, from: Date())
                let currentMonth = Calendar.current.component(.month, from: Date())
                let displayYear = month >= currentMonth ? year : year + 1
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text("\(monthName) \(String(displayYear))")
                }
                .font(Theme.bodyText)
                .foregroundStyle(Theme.textSecondary)
            }

            if let discount = sale.discount {
                HStack(spacing: 6) {
                    Image(systemName: "percent")
                        .font(.system(size: 12))
                    Text(discount)
                }
                .font(Theme.caption)
                .foregroundStyle(Theme.verdictWait)
            }
        }
        .padding(Theme.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLG)
                .stroke(Theme.verdictWait.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Pro Insight Section

    private var proInsightSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            sectionHeader(icon: "lock.fill", title: "PRO INSIGHT")

            ZStack {
                VStack(alignment: .leading, spacing: 10) {
                    if let analysis = result.proAnalysis {
                        Group {
                            Text(analysis.bestCurrentDeal ?? "Detailed deal analysis available")
                            Text(analysis.waitReason ?? "Complete price prediction model")
                            Text("Best time: \(analysis.bestTimeToBuy ?? "Personalized recommendation")")
                        }
                        .font(Theme.bodyText)
                    }
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(Theme.spacingLG)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blur(radius: 6)

                VStack(spacing: 12) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.savvitSecondary)

                    Text("Unlock Pro for full analysis")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textSecondary)

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        Text("Unlock Pro — ₹79/mo")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Theme.savvitPrimary.gradient)
                            .clipShape(Capsule())
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 140)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG))
        }
    }

    // MARK: - Citations

    private var citationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(icon: "link", title: "SOURCES")

            if let citations = result.citations {
                ForEach(Array(citations.prefix(3).enumerated()), id: \.offset) { _, url in
                    if let link = URL(string: url) {
                        Link(destination: link) {
                            Text(link.host ?? url)
                                .font(Theme.finePrint)
                                .foregroundStyle(Theme.savvitSecondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Watchlist Button

    private var watchlistButton: some View {
        Group {
            if watchlist.isInWatchlist(query: result.query) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("In Your Watchlist")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.verdictBuy)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Theme.verdictBuy.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD))
            } else {
                Button {
                    if watchlist.isAtFreeLimit {
                        showProUpgrade = true
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } else {
                        watchlist.addItem(from: result)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Watchlist")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.savvitPrimary.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMD))
                }
            }
        }
        .alert("Watchlist Full", isPresented: $showProUpgrade) {
            Button("Maybe Later", role: .cancel) {}
        } message: {
            Text("Free plan allows \(Constants.freeWatchlistLimit) items. Upgrade to Pro for unlimited tracking.")
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
        }
        .font(Theme.caption)
        .foregroundStyle(Theme.savvitPrimary)
    }
}

#Preview {
    NavigationStack {
        VerdictDetailView(result: ProductSearchResult(
            query: "iPhone 16 Pro 256GB",
            product: "iPhone 16 Pro 256GB",
            verdict: "WAIT",
            confidence: 0.9,
            shortReason: "Wait for iPhone 17 Pro launch & sales",
            reason: "The iPhone 17 Pro is expected in September 2026, which will likely trigger significant price drops on the iPhone 16 Pro.",
            bestPrice: PriceInfo(
                retailer: "Flipkart",
                price: 115900,
                currency: "INR",
                url: "https://flipkart.com",
                offers: "SBI card discount + no-cost EMI",
                inStock: true
            ),
            prices: [
                PriceInfo(retailer: "Flipkart", price: 115900, currency: "INR", url: nil, offers: "SBI card discount", inStock: true),
                PriceInfo(retailer: "Amazon India", price: 119900, currency: "INR", url: nil, offers: nil, inStock: true),
                PriceInfo(retailer: "Croma", price: 121990, currency: "INR", url: nil, offers: nil, inStock: true),
            ],
            proAnalysis: ProAnalysis(
                bestCurrentDeal: "Flipkart at ₹1,15,900 with SBI card discount",
                waitReason: "iPhone 17 Pro launches Sep 2026",
                estimatedSavings: "₹25,000-30,000",
                bestTimeToBuy: "September 2026",
                launchAlert: "iPhone 17 Pro expected September 2026"
            ),
            launchIntel: LaunchIntel(
                upcomingProduct: "iPhone 17 Pro",
                expectedDate: "September 2026",
                summary: "iPhone 17 Pro expected Sep 2026 with major design changes"
            ),
            nextSale: SaleEvent(
                name: "Flipkart Big Saving Days",
                month: 5,
                discount: "15-35% on electronics"
            ),
            priceHistory: nil,
            citations: ["https://www.apple.com", "https://www.flipkart.com"]
        ))
    }
    .preferredColorScheme(.dark)
}
