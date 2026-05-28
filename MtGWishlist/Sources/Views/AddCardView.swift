import SwiftData
import SwiftUI

/// Scryfall-backed search screen. Presented as a `.sheet` from the wishlist
/// "+" button. Lets the user filter by lang / finish / frame (mirrors the
/// Web `/add` page) and tap a result to push the AddCardForm.
struct AddCardView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var fuzzy: Bool = false
    @State private var results: [NormalizedCard] = []
    @State private var isSearching: Bool = false
    @State private var errorMessage: String? = nil
    @State private var searched: Bool = false

    @State private var langFilter: LangFilter = .ja
    @State private var finishFilter: FinishFilter = .nonfoil
    @State private var frameFilter: FrameFilter = .all

    private var visibleResults: [NormalizedCard] {
        results.filter {
            langFilter.matches($0)
                && finishFilter.matches($0)
                && frameFilter.matches($0)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            filterStack
            Divider().background(Color.separator)
            resultsContent
        }
        .background(Color.bgCanvas)
        .navigationTitle("カードを追加")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            // Dev: `--auto-search=島` (or any token) triggers an immediate
            // search on appear so we can screenshot the result grid without
            // typing into the simulator.
            if let arg = ProcessInfo.processInfo.arguments.first(
                where: { $0.hasPrefix("--auto-search=") }
            ) {
                let term = String(arg.dropFirst("--auto-search=".count))
                if !term.isEmpty {
                    query = term
                    await performSearch()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("キャンセル") { dismiss() }
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .navigationDestination(for: NormalizedCard.self) { card in
            AddCardForm(normalized: card) {
                // After successful add, pop the form *and* close the search
                // sheet entirely. The user is back on the wishlist with
                // the new item visible.
                dismiss()
            }
        }
    }

    // MARK: - Search bar

    private var searchBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color.textTertiary)
                    TextField("カード名 (英 / 日)", text: $query)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { Task { await performSearch() } }
                    if !query.isEmpty {
                        Button {
                            query = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Color.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.bgSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.separator, lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Toggle("ゆるく", isOn: $fuzzy)
                    .toggleStyle(.button)
                    .tint(Color.accentInk)
                    .font(.appCaption())
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Filters

    private var filterStack: some View {
        VStack(spacing: 8) {
            FilterChipRow(
                title: "言語",
                selection: $langFilter,
                options: LangFilter.allCases,
                label: \.label
            )
            FilterChipRow(
                title: "Finish",
                selection: $finishFilter,
                options: FinishFilter.allCases,
                label: \.label
            )
            FilterChipRow(
                title: "枠",
                selection: $frameFilter,
                options: FrameFilter.allCases,
                label: \.label
            )
        }
        .padding(.bottom, 10)
    }

    // MARK: - Results

    @ViewBuilder
    private var resultsContent: some View {
        if isSearching {
            VStack {
                Spacer()
                ProgressView()
                    .tint(Color.textSecondary)
                Spacer()
            }
        } else if let errorMessage {
            VStack(spacing: 8) {
                Spacer()
                Text(errorMessage)
                    .font(.appBody())
                    .foregroundStyle(Color.destructive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
            }
        } else if !searched {
            VStack {
                Spacer()
                Text("カード名を入力して検索")
                    .font(.appBody())
                    .foregroundStyle(Color.textTertiary)
                Spacer()
            }
        } else if visibleResults.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Text("一致するカードが見つかりません")
                    .font(.appBody())
                    .foregroundStyle(Color.textTertiary)
                if results.count > 0 {
                    Text("フィルタを緩めると \(results.count) 件出ます")
                        .font(.appCaption())
                        .foregroundStyle(Color.textTertiary)
                }
                Spacer()
            }
        } else {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12),
                    ],
                    spacing: 18
                ) {
                    ForEach(visibleResults) { card in
                        NavigationLink(value: card) {
                            SearchResultCard(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }

    // MARK: - Search action

    @MainActor
    private func performSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isSearching = true
        errorMessage = nil
        searched = true
        defer { isSearching = false }
        do {
            results = try await ScryfallClient.shared.searchCards(trimmed, fuzzy: fuzzy)
        } catch let err as ScryfallError {
            results = []
            errorMessage = "Scryfall: \(err.details)"
        } catch {
            results = []
            errorMessage = "検索エラー: \(error.localizedDescription)"
        }
    }
}
