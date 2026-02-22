import SwiftUI

struct OnboardingPageView<Visual: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let visual: Visual

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: Theme.spacingMD) {
                Text(title)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(-0.5)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)
            }
            .padding(.horizontal, Theme.horizontalPadding)

            Spacer().frame(height: 36)

            visual

            Spacer()
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45)) {
                appeared = true
            }
        }
    }
}
