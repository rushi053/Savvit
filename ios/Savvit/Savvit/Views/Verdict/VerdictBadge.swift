import SwiftUI

struct VerdictBadge: View {
    let verdict: String
    var size: CGFloat = 80

    private var verdictType: VerdictType {
        VerdictType(rawValue: verdict) ?? .wait
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(verdictType.color.opacity(0.15))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 20)

            Circle()
                .fill(verdictType.color.gradient)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: verdictType.icon)
                        .font(.system(size: size * 0.38, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }
}

#Preview {
    HStack(spacing: 40) {
        VerdictBadge(verdict: "BUY_NOW")
        VerdictBadge(verdict: "WAIT")
        VerdictBadge(verdict: "DONT_BUY")
    }
    .padding(40)
}
