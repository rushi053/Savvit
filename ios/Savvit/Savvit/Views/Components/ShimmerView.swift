import SwiftUI

struct ShimmerView: View {
    @State private var startPoint: UnitPoint = .init(x: -1.8, y: -1.2)
    @State private var endPoint: UnitPoint = .init(x: 0, y: -0.2)

    var body: some View {
        LinearGradient(
            colors: [
                Theme.bgTertiary.opacity(0.3),
                Theme.bgTertiary.opacity(0.7),
                Theme.bgTertiary.opacity(0.3),
            ],
            startPoint: startPoint,
            endPoint: endPoint
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                startPoint = .init(x: 1, y: 1)
                endPoint = .init(x: 2.8, y: 2.2)
            }
        }
    }
}

struct ShimmerCard: View {
    var height: CGFloat = 80

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.radiusLG)
            .fill(Theme.bgSecondary)
            .frame(height: height)
            .overlay(
                ShimmerView()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG))
            )
    }
}

#Preview {
    VStack(spacing: 16) {
        ShimmerCard()
        ShimmerCard(height: 100)
        ShimmerCard(height: 60)
    }
    .padding()
    .background(Theme.bgPrimary)
}
