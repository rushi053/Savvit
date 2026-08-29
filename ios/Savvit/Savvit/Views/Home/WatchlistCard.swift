import SwiftUI

struct WatchlistCard: View {
    let item: LocalWatchlistItem
    @Environment(WatchlistViewModel.self) private var watchlist
    @AppStorage("selectedRegion") private var selectedRegion = ""

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            if let imageUrl = item.productImage, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
                    default:
                        emojiFallback
                    }
                }
            } else {
                emojiFallback
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let price = item.bestPrice {
                        Text(price.formattedPrice(
                            currency: regionCurrency.code,
                            symbol: regionCurrency.symbol
                        ))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    }

                    if let drop = item.priceDropAmount {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 9, weight: .bold))
                            Text(drop.formattedPrice(
                                currency: regionCurrency.code,
                                symbol: regionCurrency.symbol
                            ))
                            .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Theme.verdictBuyText)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Theme.verdictBuyBg)
                        .clipShape(Capsule())
                    }

                    Text(verdictLabel)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.textOnLime)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.savvitLime)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .padding(Theme.spacingLG)
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(Theme.snappy) {
                    watchlist.removeItem(id: item.id)
                }
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
    }

    private var emojiFallback: some View {
        Text(productEmoji)
            .font(.system(size: 20))
            .frame(width: 44, height: 44)
            .background(Theme.savvitBlue)
            .clipShape(Circle())
    }

    private var verdictLabel: String {
        switch item.verdictType {
        case .buyNow: "Buy Now"
        case .wait: "Wait"
        case .dontBuy: "Don't Buy"
        }
    }

    private var regionCurrency: (code: String, symbol: String) {
        let region = selectedRegion.isEmpty
            ? (Locale.current.region?.identifier ?? "US")
            : selectedRegion
        let map: [String: (String, String)] = [
            "US": ("USD", "$"), "IN": ("INR", "₹"), "GB": ("GBP", "£"),
            "DE": ("EUR", "€"), "CA": ("CAD", "CA$"), "AU": ("AUD", "A$"),
            "JP": ("JPY", "¥"), "FR": ("EUR", "€"),
        ]
        let pair = map[region] ?? ("USD", "$")
        return (pair.0, pair.1)
    }

    private var productEmoji: String {
        let name = item.productName.lowercased()
        if name.contains("phone") || name.contains("iphone") || name.contains("galaxy") || name.contains("pixel") { return "📱" }
        if name.contains("airpods") || name.contains("headphone") || name.contains("wh-") || name.contains("buds") { return "🎧" }
        if name.contains("ipad") || name.contains("tab") { return "📱" }
        if name.contains("macbook") || name.contains("laptop") { return "💻" }
        if name.contains("watch") { return "⌚" }
        if name.contains("dyson") || name.contains("vacuum") { return "🧹" }
        if name.contains("ps5") || name.contains("xbox") || name.contains("switch") { return "🎮" }
        if name.contains("tv") || name.contains("monitor") { return "📺" }
        if name.contains("camera") { return "📷" }
        return "📦"
    }
}
