import SwiftUI

struct WatchlistCard: View {
    let item: LocalWatchlistItem
    @Environment(WatchlistViewModel.self) private var watchlist

    var body: some View {
        HStack(spacing: Theme.spacingMD) {
            // Verdict indicator
            Circle()
                .fill(item.verdictType.color.gradient)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: item.verdictType.icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                )
                .shadow(color: item.verdictType.color.opacity(0.3), radius: 8, y: 2)

            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)

                if let price = item.bestPrice {
                    HStack(spacing: 4) {
                        Text(price.inrFormatted)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)

                        if let retailer = item.bestRetailer {
                            Text("on \(retailer)")
                                .font(Theme.finePrint)
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                }

                Text(item.shortReason)
                    .font(Theme.caption)
                    .foregroundStyle(item.verdictType.color)
                    .lineLimit(1)
            }

            Spacer()

            // Confidence
            Text("\(Int(item.confidence * 100))%")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textTertiary)
        }
        .padding(Theme.spacingMD)
        .background(Theme.bgSecondary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG))
        .contextMenu {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3)) {
                    watchlist.removeItem(id: item.id)
                }
            } label: {
                Label("Remove from Watchlist", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation(.spring(response: 0.3)) {
                    watchlist.removeItem(id: item.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
