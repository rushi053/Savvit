import SwiftUI

struct VerdictBadge: View {
    let verdict: String
    let size: CGFloat

    private var verdictType: VerdictType {
        VerdictType(rawValue: verdict) ?? .wait
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: verdictType.icon)
                .font(.system(size: size * 0.5, weight: .bold))
            Text(verdictType.label)
                .font(.system(size: size * 0.4, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(verdictType.color.gradient)
                .shadow(color: verdictType.color.opacity(0.4), radius: 12, y: 4)
        )
    }
}

#Preview("BUY NOW") {
    VerdictBadge(verdict: "BUY_NOW", size: 44)
        .padding()
        .background(Theme.bgPrimary)
}

#Preview("WAIT") {
    VerdictBadge(verdict: "WAIT", size: 44)
        .padding()
        .background(Theme.bgPrimary)
}

#Preview("DON'T BUY") {
    VerdictBadge(verdict: "DONT_BUY", size: 44)
        .padding()
        .background(Theme.bgPrimary)
}
