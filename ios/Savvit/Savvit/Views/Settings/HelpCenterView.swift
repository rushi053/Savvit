import SwiftUI

struct HelpCenterView: View {
    @State private var expandedId: Int?
    @State private var appeared = false

    private struct FAQ {
        let icon: String
        let question: String
        let answer: String
    }

    private let faqs: [FAQ] = [
        FAQ(icon: "sparkles",
            question: "How does Savvit work?",
            answer: "You search for any product, and Savvit checks real-time prices across major retailers in your region. Our AI analyzes pricing trends, upcoming sales, and product cycles to tell you whether now's a good time to buy — or if you should wait."),
        FAQ(icon: "globe",
            question: "Where do the prices come from?",
            answer: "Prices are fetched from the web in real-time across trusted retailers. They may not always be 100% accurate — always verify on the retailer's site before purchasing."),
        FAQ(icon: "checkmark.seal.fill",
            question: "What does the verdict mean?",
            answer: "🟢 Buy Now — Good price, no major sales or price drops expected soon.\n\n🟡 Wait — A sale, new model, or price drop is likely coming soon.\n\n🔴 Don't Buy — Overpriced right now or significantly better options exist."),
        FAQ(icon: "star.fill",
            question: "What is the \"BEST\" badge?",
            answer: "The BEST badge appears on the retailer offering the lowest price among trusted, well-known retailers in your region. Other retailers are still shown for comparison."),
        FAQ(icon: "link",
            question: "Can I paste a product URL?",
            answer: "Yes! Paste any retailer URL directly into the search bar. Savvit will identify the product and fetch prices automatically."),
        FAQ(icon: "map.fill",
            question: "How do I change my region?",
            answer: "Go to Settings → Region. This changes which retailers, currency, and deals are shown. Savvit supports 8 regions globally."),
        FAQ(icon: "tag.fill",
            question: "Are deals and coupons verified?",
            answer: "Deals and coupons are sourced from the web in real-time. While we surface the most relevant ones, availability may vary. Always check terms on the retailer's site."),
        FAQ(icon: "crown.fill",
            question: "What's Savvit Pro?",
            answer: "Coming soon! Pro will unlock unlimited searches, AI price predictions, price history charts, and more."),
        FAQ(icon: "envelope.fill",
            question: "How do I contact support?",
            answer: "Tap \"Send Feedback\" in Settings or email feedback@savvit.app."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingXL) {
                heroHeader

                VStack(spacing: Theme.spacingSM) {
                    ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                        faqCard(index: index, faq: faq)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(
                                .easeOut(duration: 0.35).delay(Double(index) * 0.04),
                                value: appeared
                            )
                    }
                }

                contactCard
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.35).delay(0.4), value: appeared)
            }
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.bottom, 120)
        }
        .background(Theme.bgSecondary.ignoresSafeArea())
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { appeared = true }
    }

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(spacing: Theme.spacingMD) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Theme.savvitLime)
                .frame(width: 48, height: 48)
                .background(Theme.savvitBlue)
                .clipShape(Circle())

            Text("How can we help?")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .tracking(-0.3)

            Text("\(faqs.count) frequently asked questions")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXL)
    }

    // MARK: - FAQ Card

    private func faqCard(index: Int, faq: FAQ) -> some View {
        let isExpanded = expandedId == index

        return Button {
            withAnimation(Theme.snappy) {
                expandedId = isExpanded ? nil : index
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Theme.spacingMD) {
                    Image(systemName: faq.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.savvitLime)
                        .frame(width: 28, height: 28)
                        .background(Theme.savvitBlue)
                        .clipShape(Circle())

                    Text(faq.question)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isExpanded ? Theme.savvitBlue : Theme.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(Theme.spacingLG)

                if isExpanded {
                    Divider()
                        .padding(.horizontal, Theme.spacingLG)

                    Text(faq.answer)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                        .lineSpacing(5)
                        .padding(Theme.spacingLG)
                        .transition(.opacity)
                }
            }
            .background(Theme.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSM))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusSM)
                    .stroke(isExpanded
                        ? Theme.savvitBlue.opacity(0.15)
                        : Color.primary.opacity(0.05),
                        lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Contact Card

    private var contactCard: some View {
        VStack(spacing: Theme.spacingMD) {
            Text("Still have questions?")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

            Button {
                let subject = "Savvit Help".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Savvit%20Help"
                if let url = URL(string: "mailto:feedback@savvit.app?subject=\(subject)") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 13))
                    Text("feedback@savvit.app")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(Theme.savvitLime)
                .padding(.horizontal, Theme.spacingXL)
                .padding(.vertical, Theme.spacingMD)
                .background(Theme.savvitBlue)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.spacingXL)
        .background(Theme.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        HelpCenterView()
    }
}
