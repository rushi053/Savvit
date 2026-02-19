import SwiftUI

struct VerdictDetailView: View {
    let result: ProductSearchResult

    @Environment(WatchlistViewModel.self) private var watchlist
    @State private var showContent = false
    @State private var showProUpgrade = false

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingXL) {
                verdictCard

                if !result.prices.isEmpty {
                    whereToBuySection
                }

                if result.launchIntel != nil {
                    waitSection
                }

                if result.nextSale != nil {
                    couponsSection
                }

                if result.proAnalysis != nil {
                    proInsightCard
                }

                watchlistButton

                if let citations = result.citations, !citations.isEmpty {
                    sourcesSection(citations)
                }
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 120)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle(result.product)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                showContent = true
            }
            switch result.verdictType {
            case .buyNow: UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .wait: UINotificationFeedbackGenerator().notificationOccurred(.warning)
            case .dontBuy: UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    // MARK: - Verdict Card

    private var verdictCard: some View {
        VStack(alignment: .leading, spacing: Theme.spacingLG) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.spacingSM) {
                    HStack(spacing: Theme.spacingSM) {
                        Circle()
                            .fill(result.verdictType.color.opacity(0.15))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Image(systemName: result.verdictType.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(result.verdictType.color)
                            )

                        Text(result.verdictType.displayLabel)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(result.verdictType.textColor)
                            .tracking(-0.3)
                    }

                    Text(result.product)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }

                Spacer()

                ConfidenceRing(
                    confidence: result.confidence,
                    color: result.verdictType.color
                )
            }

            Text(result.reason)
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
        .padding(Theme.spacingXL)
        .background(result.verdictType.bgColor)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(result.verdictType.color.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Where to Buy

    private var whereToBuySection: some View {
        CardSection {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "bag")
                    .font(.system(size: 17))
                Text("Where to Buy")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.3)
            }
            .foregroundStyle(Theme.textPrimary)

            VStack(spacing: Theme.spacingSM) {
                ForEach(Array(result.prices.enumerated()), id: \.offset) { index, price in
                    retailerRow(price: price, isBest: index == 0)
                }
            }
        }
    }

    private func retailerRow(price: PriceInfo, isBest: Bool) -> some View {
        HStack(spacing: Theme.spacingMD) {
            RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                .fill(isBest ? Theme.savvitLime : Theme.bgPrimary)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "globe")
                        .font(.system(size: 14))
                        .foregroundStyle(isBest ? Theme.textOnLime : Theme.textSecondary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                        .stroke(isBest ? Color.clear : Color.primary.opacity(0.06), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(price.retailer)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)

                    if isBest {
                        Text("BEST")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(Theme.textOnLime)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Theme.savvitLime)
                            .clipShape(Capsule())
                    }
                }

                if price.inStock == false {
                    Text("Out of stock")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.danger)
                }
            }

            Spacer()

            HStack(spacing: Theme.spacingSM) {
                Text(price.price.inrFormatted)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                if let urlStr = price.url, let url = URL(string: urlStr) {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .padding(14)
        .background(isBest ? Theme.savvitLime.opacity(0.15) : Theme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay {
            if isBest {
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(Theme.savvitLime.opacity(0.5), lineWidth: 1)
            }
        }
    }

    // MARK: - If You Can Wait

    private var waitSection: some View {
        CardSection {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 17))
                Text("If You Can Wait")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.3)
            }
            .foregroundStyle(Theme.textPrimary)

            Text("Upcoming products that may affect pricing or offer better value:")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)

            if let intel = result.launchIntel {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(intel.upcomingProduct ?? "New Product")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        if let date = intel.expectedDate {
                            Text(date)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Theme.savvitLime.opacity(0.25))
                                .clipShape(Capsule())
                        }
                    }
                    if let summary = intel.summary {
                        Text(summary)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .lineSpacing(2)
                    }
                }
                .padding(Theme.spacingLG)
                .background(Theme.bgSecondary)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            }
        }
    }

    // MARK: - Coupons & Sales

    private var couponsSection: some View {
        CardSection {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "percent")
                    .font(.system(size: 17))
                Text("Coupons & Sales")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.3)
            }
            .foregroundStyle(Theme.textPrimary)

            if let sale = result.nextSale {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.verdictWait)
                        Text("Upcoming Sale")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                    }

                    Text(buildSaleDescription(sale))
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(2)
                }
                .padding(Theme.spacingLG)
                .background(Theme.verdictWaitBg)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                        .stroke(Theme.verdictWait.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Pro Insight

    private var proInsightCard: some View {
        VStack(spacing: Theme.spacingLG) {
            HStack {
                HStack(spacing: Theme.spacingSM) {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(Theme.savvitLime)
                    Text("Pro Insight")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.savvitLime)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.savvitLime.opacity(0.12))
                    .clipShape(Capsule())
            }

            ZStack {
                VStack(alignment: .leading, spacing: 6) {
                    if let analysis = result.proAnalysis {
                        Text(analysis.bestCurrentDeal ?? "Detailed price analysis available.")
                        Text(analysis.waitReason ?? "Price prediction and timing.")
                        Text("Best time: \(analysis.bestTimeToBuy ?? "See full analysis")")
                    }
                }
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.3))
                .blur(radius: 5)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: Theme.spacingMD) {
                    RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "lock.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(Theme.savvitLime)
                        )

                    Text("Unlock Pro Insights")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Unlock Pro — ₹79/mo")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textOnLime)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
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

    // MARK: - Watchlist Button

    private var watchlistButton: some View {
        Group {
            if watchlist.isInWatchlist(query: result.query) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("Added to Watchlist")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textOnBlue)
                .frame(maxWidth: .infinity)
                .frame(height: Theme.buttonHeight)
                .background(Theme.savvitBlue)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            } else {
                Button {
                    if watchlist.isAtFreeLimit {
                        showProUpgrade = true
                    } else {
                        watchlist.addItem(from: result)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "eye")
                            .font(.system(size: 20))
                        Text("Add to Watchlist")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Theme.buttonHeight)
                    .background(Theme.bgSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                }
            }
        }
        .alert("Watchlist Full", isPresented: $showProUpgrade) {
            Button("Maybe Later", role: .cancel) {}
        } message: {
            Text("Free plan allows \(Constants.freeWatchlistLimit) items. Upgrade to Pro for unlimited tracking.")
        }
    }

    // MARK: - Sources

    private func sourcesSection(_ citations: [String]) -> some View {
        CardSection {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "link")
                    .font(.system(size: 17))
                Text("Sources")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.3)
            }
            .foregroundStyle(Theme.textPrimary)

            VStack(spacing: 4) {
                ForEach(Array(citations.prefix(4).enumerated()), id: \.offset) { _, urlString in
                    if let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack(spacing: Theme.spacingMD) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Theme.textSecondary)
                                    .frame(width: 32, height: 32)
                                    .background(Theme.bgSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                Text(url.host ?? urlString)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Theme.textSecondary)
                                    .lineLimit(1)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.textTertiary)
                            }
                            .padding(.horizontal, Theme.spacingMD)
                            .padding(.vertical, Theme.spacingMD)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func buildSaleDescription(_ sale: SaleEvent) -> String {
        var parts: [String] = [sale.name]
        if let month = sale.month, (1...12).contains(month) {
            let monthName = Calendar.current.monthSymbols[month - 1]
            parts.append("expected in \(monthName)")
        }
        if let discount = sale.discount {
            parts.append(discount)
        }
        return parts.joined(separator: ". ") + "."
    }
}

// MARK: - Confidence Ring

struct ConfidenceRing: View {
    let confidence: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.06), lineWidth: 4)

            Circle()
                .trim(from: 0, to: confidence)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(Int(confidence * 100))%")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
        }
        .frame(width: 64, height: 64)
    }
}

// MARK: - Card Section (reusable bordered card)

struct CardSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingLG) {
            content
        }
        .padding(Theme.spacingXL)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        VerdictDetailView(result: ProductSearchResult(
            query: "iPhone 16 Pro 256GB",
            product: "iPhone 16 Pro 256GB",
            verdict: "WAIT",
            confidence: 0.78,
            shortReason: "Wait for price drop",
            reason: "Based on our analysis, we recommend waiting 2-3 weeks. Multiple indicators suggest a price drop is coming due to upcoming sales events.",
            bestPrice: PriceInfo(
                retailer: "Amazon", price: 115900, currency: "INR",
                url: "https://amazon.in", offers: "SBI card discount", inStock: true
            ),
            prices: [
                PriceInfo(retailer: "Amazon", price: 115900, currency: "INR", url: nil, offers: nil, inStock: true),
                PriceInfo(retailer: "Flipkart", price: 119900, currency: "INR", url: nil, offers: nil, inStock: true),
                PriceInfo(retailer: "Croma", price: 121990, currency: "INR", url: nil, offers: nil, inStock: true),
            ],
            proAnalysis: ProAnalysis(
                bestCurrentDeal: "Amazon at ₹1,15,900 with SBI card discount",
                waitReason: "Price drop expected in 2-3 weeks",
                estimatedSavings: "₹15,000-20,000",
                bestTimeToBuy: "March 2026",
                launchAlert: nil
            ),
            launchIntel: LaunchIntel(
                upcomingProduct: "iPhone 17 Pro",
                expectedDate: "September 2026",
                summary: "Direct successor with improved camera and design"
            ),
            nextSale: SaleEvent(name: "Amazon Great Indian Festival", month: 3, discount: "15-35% on electronics"),
            priceHistory: nil,
            citations: ["https://www.apple.com", "https://www.amazon.in"]
        ))
    }
    .environment(WatchlistViewModel())
}
