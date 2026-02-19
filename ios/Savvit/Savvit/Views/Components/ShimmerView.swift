import SwiftUI

struct ShimmerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var phase: CGFloat = -1.5

    var body: some View {
        let shimmer = colorScheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white.opacity(0.8)

        LinearGradient(
            colors: [.clear, shimmer, .clear],
            startPoint: .init(x: phase - 0.5, y: 0.5),
            endPoint: .init(x: phase + 0.5, y: 0.5)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false)) {
                phase = 2.0
            }
        }
    }
}

struct ShimmerCard: View {
    var height: CGFloat = 80

    var body: some View {
        RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .fill(Theme.bgSecondary)
            .frame(height: height)
            .overlay(
                ShimmerView()
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
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
}
