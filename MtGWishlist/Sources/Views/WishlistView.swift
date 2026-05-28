import SwiftData
import SwiftUI

/// Root screen — the wishlist itself. Read-only at Phase 2: just queries the
/// SwiftData store, filters by selected format, groups by format, and
/// renders the result as a 2-column adaptive grid of `WishlistCardView`s.
///
/// Mirrors the Web `WishlistContent` component in structure (filter tabs at
/// the top, then format-grouped sections of card grids). Phase 3 will add
/// the search/add flow accessed via the toolbar `+` button.
struct WishlistView: View {
    @Environment(\.modelContext) private var context

    /// All wishlist items, newest first. Filtering / grouping happens in-memory
    /// because SwiftData `@Query` doesn't support dynamic Predicates from
    /// `@State` props cleanly across iOS 17 / 18 / 26 — keep it simple.
    @Query(sort: [SortDescriptor(\WishlistItem.createdAt, order: .reverse)])
    private var items: [WishlistItem]

    @State private var formatFilter: FormatFilter = nil
    @State private var showStyleGuide = false

    var body: some View {
        NavigationStack {
            content
                // System title would render in San Francisco; we hide it and
                // draw our own Vidaloka hero in the scroll content (see
                // `heroHeader` below) to preserve the design-token typography.
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar }
                .toolbarBackground(Color.bgCanvas, for: .navigationBar)
        }
        .background(Color.bgCanvas.ignoresSafeArea())
        .sheet(isPresented: $showStyleGuide) {
            StyleGuideView()
        }
        // Dev-only auto-seed: pass `--seed-samples` as a launch argument
        // (`xcrun simctl launch ... com.mtgtools.wishlist --seed-samples`)
        // to populate sample data without manually tapping the button. Skips
        // re-seeding once the store already has rows so repeated launches
        // don't duplicate.
        .task {
            if ProcessInfo.processInfo.arguments.contains("--seed-samples"),
               items.isEmpty {
                SeedData.insertSamples(into: context)
            }
        }
    }

    // MARK: - Hero

    /// "WISHLIST" hero, rendered in Vidaloka. Lives inside the scroll content
    /// so it scrolls away naturally (no clever sticky-header animation; the
    /// large title is just an opening flourish).
    private var heroHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("WISHLIST")
                .font(.appDisplayLarge())
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    // MARK: - Body content

    @ViewBuilder
    private var content: some View {
        let visible = filtered

        ScrollView {
            VStack(spacing: 0) {
                heroHeader

                if visible.isEmpty {
                    EmptyStateView(
                        onSeed: { SeedData.insertSamples(into: context) }
                    )
                } else {
                    FormatFilterTabs(selection: $formatFilter)
                        .padding(.bottom, 4)

                    ForEach(groupedByFormat(visible), id: \.format) { group in
                        formatSection(
                            group: group,
                            isFirst: group.format == groupedByFormat(visible).first?.format
                        )
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(Color.bgCanvas)
    }

    // MARK: - Filter + group

    private var filtered: [WishlistItem] {
        guard let f = formatFilter else { return items }
        return items.filter { $0.formatTag == f.rawValue }
    }

    /// Bucket items by their `formatTag` in the canonical FormatTag order
    /// (matches the Web `groupByFormat` helper). Items with a nil/unknown
    /// format fall into the `.other` bucket so they're still visible.
    private func groupedByFormat(_ items: [WishlistItem]) -> [FormatGroup] {
        var buckets: [FormatTag: [WishlistItem]] = [:]
        for item in items {
            let tag = item.formatTag.flatMap(FormatTag.init(rawValue:)) ?? .other
            buckets[tag, default: []].append(item)
        }
        return FormatTag.allCases.compactMap { tag in
            guard let rows = buckets[tag], !rows.isEmpty else { return nil }
            return FormatGroup(format: tag, rows: rows)
        }
    }

    // MARK: - Section render

    @ViewBuilder
    private func formatSection(group: FormatGroup, isFirst: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("\(group.format.label) (\(group.rows.count))")
                    .font(.appCaption().weight(.semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.textSecondary)
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, isFirst == true ? 8 : 24)
            .padding(.bottom, 6)
            .overlay(alignment: .top) {
                if isFirst == false {
                    Rectangle()
                        .fill(Color.separator)
                        .frame(height: 0.5)
                        .padding(.horizontal, 16)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 20
            ) {
                ForEach(group.rows) { item in
                    WishlistCardView(item: item)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    SeedData.insertSamples(into: context)
                } label: {
                    Label("サンプル追加", systemImage: "tray.and.arrow.down")
                }
                Button(role: .destructive) {
                    SeedData.wipeAll(in: context)
                } label: {
                    Label("全データ削除 (Debug)", systemImage: "trash")
                }
                Divider()
                Button {
                    showStyleGuide = true
                } label: {
                    Label("Style Guide", systemImage: "paintpalette")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.textPrimary)
            }
        }
    }
}

// MARK: - Internal types

private struct FormatGroup {
    let format: FormatTag
    let rows: [WishlistItem]
}

// MARK: - Empty state

/// Shown when the wishlist is empty. Mirrors the Web build's EmptyState in
/// intent — points the user toward the add flow. For Phase 2 (no /add yet)
/// we offer "サンプル追加" so the design can be eyeballed without typing
/// boilerplate seed code.
private struct EmptyStateView: View {
    let onSeed: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("ウィッシュリストは空です")
                .font(.appBody())
                .foregroundStyle(Color.textSecondary)
            Button(action: onSeed) {
                Text("サンプル追加")
                    .font(.appCaption().weight(.semibold))
                    .foregroundStyle(Color.bgCanvas)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.accentInk))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 120)
    }
}
