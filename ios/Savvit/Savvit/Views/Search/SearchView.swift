import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool

    private let trendingItems = ["iPhone 16", "MacBook Air M4", "PS5 Pro", "AirPods 4", "Dyson V15"]

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    searchBar
                        .padding(.top, Theme.spacingXXL)

                    if viewModel.isResolvingURL {
                        Text("Identifying product...")
                            .font(Theme.footnote)
                            .foregroundStyle(Theme.savvitBlue)
                            .padding(.top, Theme.spacingSM)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if !viewModel.recentSearches.isEmpty {
                        recentSearches
                            .padding(.top, 36)
                    }

                    trending
                        .padding(.top, 32)
                }
                .padding(.horizontal, Theme.horizontalPadding)
                .padding(.top, 60)
                .padding(.bottom, 120)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.bgPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isResolvingURL)
            .navigationDestination(isPresented: $vm.showVerdict) {
                AnalyzingResultView(viewModel: viewModel)
            }
            .alert("Something went wrong", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("Try Again") {
                    Task { await viewModel.unifiedSearch() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            Image("SavvitLogo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                .shadow(color: Theme.savvitBlue.opacity(0.2), radius: 12, y: 4)

            Text("Savvit")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .tracking(-0.5)
                .padding(.top, Theme.spacingMD)

            Text("Should you buy it now or wait?")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, Theme.spacingXS)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 0) {
            if viewModel.isResolvingURL {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(Theme.savvitBlue)
                    .padding(.leading, Theme.spacingLG)
            } else if hasQuery {
                Button {
                    viewModel.searchQuery = ""
                    viewModel.resolvedProductName = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.leading, Theme.spacingLG)
                }
            } else {
                Image(systemName: viewModel.isURL(viewModel.searchQuery) ? "link" : "magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.savvitBlue.opacity(isSearchFocused ? 1 : 0.5))
                    .padding(.leading, Theme.spacingLG)
                    .contentTransition(.symbolEffect(.replace))
            }

            TextField("Search a product or paste a link...", text: $viewModel.searchQuery)
                .font(.system(size: 15))
                .foregroundStyle(Theme.textPrimary)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(viewModel.isURL(viewModel.searchQuery))
                .padding(.horizontal, Theme.spacingMD)
                .onSubmit { performSearch() }

            Button { performSearch() } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        hasQuery ? Theme.savvitLime : Theme.textTertiary
                    )
                    .frame(width: 40, height: 40)
                    .background(hasQuery ? Theme.savvitBlue : Theme.bgTertiary)
                    .clipShape(Circle())
            }
            .padding(.trailing, 6)
        }
        .frame(height: Theme.inputHeight)
        .background(isSearchFocused ? Theme.bgPrimary : Theme.bgSecondary)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Theme.savvitBlue, lineWidth: isSearchFocused ? 2 : 1)
        )
        .shadow(
            color: Theme.savvitBlue.opacity(isSearchFocused ? 0.2 : 0.1),
            radius: isSearchFocused ? 12 : 8,
            y: 2
        )
        .animation(.easeInOut(duration: 0.25), value: isSearchFocused)
    }

    // MARK: - Recent Searches

    private var recentSearches: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.savvitBlue)
                    Text("Recent Searches")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                        .tracking(-0.3)
                }

                Spacer()

                Button {
                    viewModel.recentSearches.removeAll()
                    UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.recentSearches)
                } label: {
                    Text("Clear All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.savvitBlue)
                }
            }

            VStack(spacing: 2) {
                ForEach(Array(viewModel.recentSearches.prefix(5).enumerated()), id: \.element) { _, query in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.searchRecent(query)
                    } label: {
                        HStack(spacing: Theme.spacingMD) {
                            Image(systemName: viewModel.isURL(query) ? "link" : "clock")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.savvitLime)
                                .frame(width: 32, height: 32)
                                .background(Theme.savvitBlue)
                                .clipShape(Circle())

                            Text(query)
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.textTertiary)
                        }
                        .padding(.horizontal, Theme.spacingMD)
                        .padding(.vertical, Theme.spacingMD)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Trending

    private var trending: some View {
        VStack(alignment: .leading, spacing: Theme.spacingMD) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.savvitBlue)
                Text("Trending")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .tracking(-0.3)
            }

            FlowLayout(spacing: 8) {
                ForEach(trendingItems, id: \.self) { item in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        viewModel.searchQuery = item
                        performSearch()
                    } label: {
                        Text(item)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.textOnLime)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Theme.savvitLime)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private var hasQuery: Bool {
        !viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func performSearch() {
        guard hasQuery else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isSearchFocused = false
        Task { await viewModel.unifiedSearch() }
    }
}

// MARK: - Analyzing + Result Wrapper

/// Manages the analyzing animation, then transitions to the verdict once
/// both the API has responded AND the step animation has completed.
private struct AnalyzingResultView: View {
    var viewModel: SearchViewModel
    @Environment(WatchlistViewModel.self) private var watchlist

    @State private var visibleSteps = 0
    @State private var checkedSteps = 0
    @State private var apiDone = false
    @State private var animationDone = false
    @State private var iconRotation: Double = 0

    private let steps = [
        "Scanning retailers",
        "Checking price history",
        "Finding coupons",
        "Analyzing trends",
    ]

    var body: some View {
        Group {
            if animationDone, let result = viewModel.searchResult {
                VerdictDetailView(result: result)
            } else {
                analyzingContent
            }
        }
    }

    // MARK: - Analyzing Content

    private var analyzingContent: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 80)

            Image("SavvitLogo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusMD))
                .rotationEffect(.degrees(iconRotation))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: iconRotation)
                .padding(.bottom, Theme.spacingXXL)

            Text("Researching \"\(viewModel.searchQuery)\"")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.spacingXXL)

            Text("Checking prices, sales & upcoming launches...")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .padding(.top, Theme.spacingSM)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    if index < visibleSteps {
                        HStack(spacing: Theme.spacingMD) {
                            ZStack {
                                Circle()
                                    .fill(index < checkedSteps ? Theme.savvitBlue : Theme.bgSecondary)
                                    .frame(width: 28, height: 28)

                                if index < checkedSteps {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(Theme.savvitLime)
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                        .tint(Theme.textSecondary)
                                }
                            }

                            Text(steps[index])
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.top, Theme.spacingLG)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
            }
            .padding(.top, 32)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.bgPrimary.ignoresSafeArea())
        .navigationTitle("Analyzing...")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startAnimation() }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            if !isLoading && viewModel.searchResult != nil {
                apiDone = true
            }
        }
    }

    // MARK: - Animation Orchestrator

    private func startAnimation() {
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            await MainActor.run { iconRotation = 360 }
        }

        Task {
            for i in 0..<4 {
                // Reveal this step
                withAnimation(.easeOut(duration: 0.3)) {
                    visibleSteps = i + 1
                }

                // Wait before checking — fast if API done, normal pace otherwise
                let checkDelay: Duration = apiDone ? .milliseconds(200) : .milliseconds(600)
                try? await Task.sleep(for: checkDelay)

                // Check this step
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    checkedSteps = i + 1
                }

                // Gap before revealing next step
                if i < 3 {
                    let gap: Duration = apiDone ? .milliseconds(150) : .milliseconds(400)
                    try? await Task.sleep(for: gap)
                }
            }

            // All 4 steps animated — wait for API if still running
            while !apiDone {
                try? await Task.sleep(for: .milliseconds(100))
            }

            // Brief pause so the user sees all checks before transitioning
            try? await Task.sleep(for: .milliseconds(500))

            withAnimation(.easeInOut(duration: 0.3)) {
                animationDone = true
            }
        }
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }

        return CGSize(width: width, height: y + maxHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            maxHeight = max(maxHeight, size.height)
            x += size.width + spacing
        }
    }
}

#Preview {
    SearchView()
}
