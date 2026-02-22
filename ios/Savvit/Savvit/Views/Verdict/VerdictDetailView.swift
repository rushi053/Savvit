import SwiftUI
import StoreKit

struct VerdictDetailView: View {
    let result: ProductSearchResult

    @Environment(WatchlistViewModel.self) private var watchlist
    @AppStorage("selectedRegion") private var selectedRegion = ""
    @State private var showContent = false
    @State private var showProUpgrade = false
    @State private var showProComingSoon = false
    @State private var copiedDealId: String?

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacingXL) {
                verdictCard

                if !validPrices.isEmpty {
                    whereToBuySection
                }

                if result.launchIntel != nil {
                    waitSection
                }

                if hasDealsOrSales {
                    dealsSection
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
        VStack(alignment: .leading, spacing: 0) {
            if let imageUrl = result.productImage, let url = URL(string: imageUrl) {
                imageHero(url: url)
            }

            VStack(alignment: .leading, spacing: Theme.spacingLG) {
                HStack(alignment: .center) {
                    verdictPill

                    Spacer()

                    ConfidenceRing(
                        confidence: result.confidence,
                        color: result.verdictType.color
                    )
                }

                Text(result.product)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(-0.3)

                Text(result.reason)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(3)

                if let topDeal = result.proAnalysis?.topDeal {
                    HStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.savvitLime)
                        Text(topDeal)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                    }
                    .padding(Theme.spacingMD)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.savvitLime.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                }
            }
            .padding(Theme.spacingXL)
        }
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var verdictPill: some View {
        HStack(spacing: 6) {
            Image(systemName: result.verdictType.icon)
                .font(.system(size: 13))
            Text(result.verdictType.displayLabel)
                .font(.system(size: 13, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(result.verdictType.color)
        .clipShape(Capsule())
    }

    private func imageHero(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                Color.clear
                    .frame(height: 220)
                    .overlay {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .clipped()
                    .overlay(alignment: .bottom) {
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: Theme.bgPrimary.opacity(0.6), location: 0.7),
                                .init(color: Theme.bgPrimary, location: 1),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                    }
            case .failure:
                EmptyView()
            default:
                RoundedRectangle(cornerRadius: 0)
                    .fill(Theme.bgSecondary)
                    .frame(height: 200)
                    .overlay(ProgressView())
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: Theme.cornerRadius,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: Theme.cornerRadius
            )
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
                ForEach(Array(validPrices.enumerated()), id: \.offset) { index, price in
                    retailerRow(price: price, isBest: index == 0)
                }
            }

            Text("Prices are fetched from the web and may not be accurate. Always verify on the retailer's site before purchasing. Savvit is not responsible for third-party pricing or transactions.")
                .font(.system(size: 11))
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, Theme.spacingSM)
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
                Text(price.price.formattedPrice(
                    currency: resolvedCurrency.code,
                    symbol: resolvedCurrency.symbol
                ))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)

                if let urlStr = price.url, let url = URL(string: urlStr) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        Analytics.track("retailer_link_tapped", properties: [
                            "retailer": price.retailer,
                            "product": result.product
                        ])
                        UIApplication.shared.open(url)
                    } label: {
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

    // MARK: - Deals & Coupons

    private var hasDealsOrSales: Bool {
        (result.deals != nil && !result.deals!.isEmpty) || result.nextSale != nil
    }

    private var dealsSection: some View {
        CardSection {
            HStack(spacing: Theme.spacingSM) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 17))
                Text("Deals & Coupons")
                    .font(.system(size: 17, weight: .semibold))
                    .tracking(-0.3)
            }
            .foregroundStyle(Theme.textPrimary)

            if let summary = result.dealsSummary {
                Text(summary)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }

            if let deals = result.deals {
                VStack(spacing: Theme.spacingSM) {
                    ForEach(Array(deals.enumerated()), id: \.offset) { _, deal in
                        dealCard(deal)
                    }
                }
            }

            if let sale = result.nextSale {
                upcomingSaleCard(sale)
            }
        }
    }

    private func dealCard(_ deal: Deal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: dealIcon(for: deal.type))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.savvitLime)
                    .frame(width: 30, height: 30)
                    .background(Theme.savvitBlue)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(deal.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)

                        if let discount = deal.discount {
                            Text(discount)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.textOnLime)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Theme.savvitLime)
                                .clipShape(Capsule())
                        }
                    }

                    if let retailer = deal.retailer {
                        Text(retailer)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textTertiary)
                    }
                }

                Spacer(minLength: 0)
            }

            Text(deal.description)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(2)

            HStack(spacing: Theme.spacingMD) {
                if let code = deal.code {
                    couponCodeBadge(code, dealTitle: deal.title)
                }

                if let validUntil = deal.validUntil {
                    Spacer(minLength: 0)
                    Text("Valid until \(validUntil)")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
        .padding(Theme.spacingLG)
        .background(deal.type == "bank_offer"
            ? Theme.savvitBlue.opacity(0.04)
            : Theme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(deal.type == "bank_offer"
                    ? Theme.savvitBlue.opacity(0.1)
                    : Color.clear,
                    lineWidth: 1)
        )
    }

    private func couponCodeBadge(_ code: String, dealTitle: String) -> some View {
        let isCopied = copiedDealId == dealTitle
        return Button {
            UIPasteboard.general.string = code
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) { copiedDealId = dealTitle }
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if copiedDealId == dealTitle { copiedDealId = nil }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 10))
                Text(isCopied ? "Copied!" : code)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(isCopied ? Theme.verdictBuy : Theme.savvitBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isCopied ? Theme.verdictBuy.opacity(0.1) : Theme.savvitBlue.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(isCopied ? Theme.verdictBuy.opacity(0.3) : Theme.savvitBlue.opacity(0.2))
            )
            .contentTransition(.symbolEffect(.replace))
        }
    }

    private func upcomingSaleCard(_ sale: SaleEvent) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.verdictWait)
                Text("Coming Up")
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

    private func dealIcon(for type: String) -> String {
        switch type {
        case "coupon": "ticket.fill"
        case "bank_offer": "creditcard.fill"
        case "cashback", "exchange": "arrow.triangle.2.circlepath"
        case "student": "graduationcap.fill"
        case "bundle": "shippingbox.fill"
        case "sale": "percent"
        default: "tag.fill"
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
                Analytics.track("pro_tapped", properties: ["product": result.product, "context": "verdict_detail"])
                showProComingSoon = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("Unlock Pro — \(proPriceLabel)")
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
        .alert("Coming Soon", isPresented: $showProComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Savvit Pro is coming soon! We'll notify you when it's ready.")
        }
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
            Button("OK", role: .cancel) {}
        } message: {
            Text("You're tracking \(Constants.freeWatchlistLimit) items — that's the free limit. Savvit Pro (coming soon) will unlock unlimited tracking.")
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

    private var validPrices: [PriceInfo] {
        result.prices.filter { $0.price > 0 }
    }

    private var resolvedRegionCode: String {
        if let code = result.region?.code { return code }
        let saved = selectedRegion
        if !saved.isEmpty { return saved }
        return Locale.current.region?.identifier ?? "US"
    }

    private var resolvedCurrency: (code: String, symbol: String) {
        if let r = result.region { return (r.currency, r.currencySymbol) }
        let map: [String: (String, String)] = [
            "US": ("USD", "$"), "IN": ("INR", "₹"), "GB": ("GBP", "£"),
            "DE": ("EUR", "€"), "CA": ("CAD", "CA$"), "AU": ("AUD", "A$"),
            "JP": ("JPY", "¥"), "FR": ("EUR", "€"),
        ]
        let pair = map[resolvedRegionCode] ?? ("USD", "$")
        return (pair.0, pair.1)
    }

    private var proPriceLabel: String {
        resolvedRegionCode == "IN" ? "₹79/mo" : "$4.99/mo"
    }

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
                launchAlert: nil,
                topDeal: "Use HDFC card on Flipkart for ₹5,000 instant discount"
            ),
            launchIntel: LaunchIntel(
                upcomingProduct: "iPhone 17 Pro",
                expectedDate: "September 2026",
                summary: "Direct successor with improved camera and design"
            ),
            nextSale: SaleEvent(name: "Amazon Great Indian Festival", month: 3, discount: "15-35% on electronics"),
            priceHistory: nil,
            citations: ["https://www.apple.com", "https://www.amazon.in"],
            region: RegionInfo(code: "IN", currency: "INR", currencySymbol: "₹"),
            productImage: nil,
            deals: [
                Deal(type: "bank_offer", title: "HDFC Card Offer", description: "₹5,000 instant discount on HDFC credit cards", code: nil, retailer: "Flipkart", discount: "₹5,000 off", validUntil: "March 15, 2026", source: nil),
                Deal(type: "coupon", title: "Extra 10% Off", description: "Use code for additional 10% off (max ₹2,000)", code: "SAVE10", retailer: "Amazon", discount: "10% off", validUntil: nil, source: nil),
                Deal(type: "cashback", title: "Amazon Pay Cashback", description: "5% cashback with Amazon Pay ICICI card", code: nil, retailer: "Amazon", discount: "5% cashback", validUntil: nil, source: nil),
            ],
            dealsSummary: "Best deal: ₹5,000 off with HDFC card on Flipkart"
        ))
    }
    .environment(WatchlistViewModel())
}
