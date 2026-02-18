import SwiftUI

struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ZStack {
                Theme.bgPrimary.ignoresSafeArea()

                if viewModel.isLoading {
                    searchLoadingView
                        .transition(.opacity)
                } else {
                    searchContent
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
            .navigationTitle("Search")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: $vm.showVerdict) {
                if let result = viewModel.searchResult {
                    VerdictDetailView(result: result)
                }
            }
            .alert("Something went wrong", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("Try Again") {
                    Task { await viewModel.search() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
        }
    }

    // MARK: - Search Content

    private var searchContent: some View {
        ScrollView {
            VStack(spacing: Theme.spacingXL) {
                searchBar

                if !viewModel.recentSearches.isEmpty {
                    recentSearchesList
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, Theme.spacingLG)
            .padding(.top, Theme.spacingSM)
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            try? await Task.sleep(for: .milliseconds(400))
            isSearchFocused = true
        }
    }

    private var searchBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                if viewModel.isResolvingURL {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(Theme.savvitPrimary)
                } else {
                    Image(systemName: viewModel.isURL(viewModel.searchQuery) ? "link" : "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .contentTransition(.symbolEffect(.replace))
                }

                TextField("Search or paste a product link...", text: $viewModel.searchQuery)
                    .font(Theme.bodyText)
                    .foregroundStyle(Theme.textPrimary)
                    .focused($isSearchFocused)
                    .submitLabel(.search)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(viewModel.isURL(viewModel.searchQuery))
                    .onSubmit {
                        Task { await viewModel.unifiedSearch() }
                    }

                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.searchQuery = ""
                        viewModel.resolvedProductName = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
            .padding(Theme.spacingMD)
            .background(Theme.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.radiusLG))

            if viewModel.isResolvingURL {
                Text("Identifying product...")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.savvitPrimary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.isResolvingURL)
    }

    private var recentSearchesList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent searches")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textTertiary)
                Spacer()
            }

            ForEach(viewModel.recentSearches, id: \.self) { query in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.searchRecent(query)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textTertiary)
                        Text(query)
                            .font(Theme.bodyText)
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: "arrow.up.left")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: - Loading View

    private var searchLoadingView: some View {
        VStack(spacing: Theme.spacingXXL) {
            Spacer()

            VStack(spacing: Theme.spacingLG) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(Theme.savvitPrimary)
                    .symbolEffect(.pulse)

                Text(viewModel.loadingStep)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.4), value: viewModel.loadingStep)
            }

            VStack(spacing: Theme.spacingMD) {
                ShimmerCard()
                ShimmerCard(height: 100)
                ShimmerCard(height: 60)
            }
            .padding(.horizontal, Theme.spacingLG)

            Spacer()
        }
    }
}

#Preview {
    SearchView()
        .preferredColorScheme(.dark)
}
