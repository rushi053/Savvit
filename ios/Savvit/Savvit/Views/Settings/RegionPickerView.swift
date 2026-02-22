import SwiftUI

struct RegionPickerView: View {
    @AppStorage("selectedRegion") private var selectedRegion = ""
    @Environment(\.dismiss) private var dismiss

    private let regions: [(code: String, flag: String, name: String, currency: String)] = [
        ("", "🌐", "Auto-detect", "Device locale"),
        ("US", "🇺🇸", "United States", "$"),
        ("IN", "🇮🇳", "India", "₹"),
        ("GB", "🇬🇧", "United Kingdom", "£"),
        ("DE", "🇩🇪", "Germany", "€"),
        ("CA", "🇨🇦", "Canada", "CA$"),
        ("AU", "🇦🇺", "Australia", "A$"),
        ("JP", "🇯🇵", "Japan", "¥"),
        ("FR", "🇫🇷", "France", "€"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(Array(regions.enumerated()), id: \.offset) { index, region in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedRegion = region.code
                        dismiss()
                    } label: {
                        HStack(spacing: Theme.spacingMD) {
                            Text(region.flag)
                                .font(.system(size: 24))
                                .frame(width: 36, height: 36)

                            VStack(alignment: .leading, spacing: 1) {
                                Text(region.name)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(region.currency)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()

                            if selectedRegion == region.code {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.savvitBlue)
                            }
                        }
                        .padding(.horizontal, Theme.spacingLG)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    if index < regions.count - 1 {
                        Divider()
                            .padding(.leading, 64)
                    }
                }
            }
            .background(Theme.bgPrimary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadiusMD)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .padding(.horizontal, Theme.horizontalPadding)
            .padding(.top, Theme.spacingLG)
            .padding(.bottom, 100)
        }
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle("Region")
        .navigationBarTitleDisplayMode(.inline)
    }
}
