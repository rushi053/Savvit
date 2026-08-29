import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    private var pro = ProManager.shared

    @State private var selectedProductID: String = Constants.proYearlyID
    @State private var showError = false

    /// Where the paywall was opened from — for analytics only.
    let context: String

    init(context: String = "unknown") {
        self.context = context
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                        .padding(.top, Theme.spacingXL)
                        .padding(.bottom, Theme.spacingXXL)

                    features
                        .padding(.bottom, Theme.spacingXXL)

                    if pro.products.isEmpty {
                        loadingOrError
                    } else {
                        planPicker
                            .padding(.bottom, Theme.spacingXL)
                        purchaseButton
                        trialCaption
                            .padding(.top, Theme.spacingMD)
                    }

                    footer
                        .padding(.top, Theme.spacingXXL)
                        .padding(.bottom, Theme.spacingXL)
                }
                .padding(.horizontal, Theme.horizontalPadding)
            }
            .background(Theme.bgPrimary.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Theme.bgSecondary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .task {
            Analytics.track("paywall_shown", properties: ["context": context])
            await pro.loadProductsIfNeeded()
        }
        .onChange(of: pro.isPro) { _, isPro in
            if isPro { dismiss() }
        }
        .alert("Something went wrong", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(pro.lastError ?? "Please try again.")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Theme.spacingLG) {
            Image(systemName: "crown.fill")
                .font(.system(size: 30))
                .foregroundStyle(Theme.savvitLime)
                .frame(width: 72, height: 72)
                .background(Theme.savvitBlue)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                .shadow(color: Theme.savvitBlue.opacity(0.25), radius: 14, y: 6)

            VStack(spacing: 6) {
                Text("Savvit Pro")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(-0.5)

                Text("Stop checking prices.\nWe'll tell you when it's time to buy.")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Features

    private var features: some View {
        VStack(spacing: 0) {
            featureRow(
                icon: "bell.badge.fill",
                title: "Price-drop alerts",
                subtitle: "Get notified when a watched product gets cheaper or flips to Buy Now"
            )
            featureDivider
            featureRow(
                icon: "eye.fill",
                title: "Unlimited watchlist",
                subtitle: "Track every product you're deciding on — no 3-item limit"
            )
            featureDivider
            featureRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Always-fresh prices",
                subtitle: "Your watchlist re-checks prices automatically, even in the background"
            )
        }
        .background(Theme.bgSecondary.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: Theme.spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Theme.savvitLime)
                .frame(width: 32, height: 32)
                .background(Theme.savvitBlue)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineSpacing(2)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.spacingLG)
    }

    private var featureDivider: some View {
        Divider().padding(.leading, 60)
    }

    // MARK: - Plans

    private var planPicker: some View {
        VStack(spacing: Theme.spacingMD) {
            ForEach(orderedProducts, id: \.id) { product in
                planCard(product)
            }
        }
    }

    private var orderedProducts: [Product] {
        // Yearly first — it's the default selection
        pro.products.sorted { $0.price > $1.price }
    }

    private func planCard(_ product: Product) -> some View {
        let isSelected = product.id == selectedProductID
        let isYearly = product.id == Constants.proYearlyID

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(Theme.snappy) { selectedProductID = product.id }
        } label: {
            HStack(spacing: Theme.spacingMD) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.savvitBlue : Theme.textTertiary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(isYearly ? "Yearly" : "Monthly")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)

                        if isYearly, let savings = yearlySavingsPercent {
                            Text("SAVE \(savings)%")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(0.5)
                                .foregroundStyle(Theme.textOnLime)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.savvitLime)
                                .clipShape(Capsule())
                        }
                    }

                    if isYearly, let monthlyEquivalent = yearlyPerMonthText(product) {
                        Text(monthlyEquivalent)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }

                Spacer()

                Text("\(product.displayPrice)\(isYearly ? "/yr" : "/mo")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(Theme.spacingLG)
            .background(Theme.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(isSelected ? Theme.savvitBlue : Color.primary.opacity(0.08),
                            lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var yearlySavingsPercent: Int? {
        guard let monthly = pro.monthlyProduct, let yearly = pro.yearlyProduct else { return nil }
        let fullYear = monthly.price * 12
        guard fullYear > 0 else { return nil }
        let ratio = (fullYear - yearly.price) / fullYear
        let percent = Int((ratio as NSDecimalNumber).doubleValue * 100)
        return percent > 0 ? percent : nil
    }

    private func yearlyPerMonthText(_ yearly: Product) -> String? {
        let perMonth = yearly.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = yearly.priceFormatStyle.locale
        guard let text = formatter.string(from: perMonth as NSDecimalNumber) else { return nil }
        return "\(text)/month, billed annually"
    }

    // MARK: - Purchase

    private var selectedProduct: Product? {
        pro.products.first { $0.id == selectedProductID } ?? pro.products.first
    }

    private var purchaseButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            Task {
                let success = await pro.purchase(product)
                if !success, pro.lastError != nil { showError = true }
            }
        } label: {
            HStack(spacing: 8) {
                if pro.purchaseInFlight {
                    ProgressView()
                        .tint(Theme.textOnLime)
                } else {
                    Image(systemName: "sparkles")
                    Text(ctaText)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.textOnLime)
            .frame(maxWidth: .infinity)
            .frame(height: Theme.buttonHeight)
            .background(Theme.savvitLime)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        }
        .disabled(pro.purchaseInFlight || selectedProduct == nil)
    }

    private var ctaText: String {
        if let offer = selectedProduct?.subscription?.introductoryOffer,
           offer.paymentMode == .freeTrial {
            return "Start \(periodText(offer.period)) Free Trial"
        }
        return "Unlock Savvit Pro"
    }

    private var trialCaption: some View {
        Group {
            if let product = selectedProduct {
                if let offer = product.subscription?.introductoryOffer, offer.paymentMode == .freeTrial {
                    Text("Free for \(periodText(offer.period).lowercased()), then \(product.displayPrice)/\(product.id == Constants.proYearlyID ? "year" : "month"). Cancel anytime.")
                } else {
                    Text("Auto-renews. Cancel anytime in Settings.")
                }
            }
        }
        .font(.system(size: 12))
        .foregroundStyle(Theme.textTertiary)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private func periodText(_ period: Product.SubscriptionPeriod) -> String {
        let unit: String
        switch period.unit {
        case .day: unit = period.value == 7 ? "1 Week" : "\(period.value) Days"
        case .week: unit = period.value == 1 ? "1 Week" : "\(period.value) Weeks"
        case .month: unit = period.value == 1 ? "1 Month" : "\(period.value) Months"
        case .year: unit = period.value == 1 ? "1 Year" : "\(period.value) Years"
        @unknown default: unit = "\(period.value)"
        }
        return unit
    }

    // MARK: - Loading / Error

    private var loadingOrError: some View {
        VStack(spacing: Theme.spacingLG) {
            if pro.isLoadingProducts {
                ProgressView()
                Text("Loading plans…")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
            } else {
                Text(pro.lastError ?? "Plans aren't available right now.")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Try Again") {
                    Task { await pro.loadProductsIfNeeded() }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.savvitBlue)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXXL)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Theme.spacingMD) {
            Button {
                Task { await pro.restorePurchases() }
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }

            HStack(spacing: Theme.spacingLG) {
                Link("Privacy Policy", destination: URL(string: "https://savvit.app/privacy")!)
                Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(.system(size: 12))
            .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PaywallView(context: "preview")
}
