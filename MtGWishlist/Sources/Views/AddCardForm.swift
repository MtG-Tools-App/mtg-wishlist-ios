import SwiftData
import SwiftUI

/// Detail form pushed when the user taps a search result. Captures the
/// wishlist row metadata (format / condition / target price / qty / notes)
/// and commits via `Card.upsert` + `insertWishlistItem`.
///
/// On successful add the parent sheet dismisses entirely (via the `onAdded`
/// closure) so the user lands back on the wishlist with the new entry
/// visible — same dismissal flow as the Web `/add` page's `router.push("/")`.
struct AddCardForm: View {
    let normalized: NormalizedCard
    /// Called after a successful insert. The parent typically dismisses
    /// the AddCardView sheet here.
    let onAdded: () -> Void

    @Environment(\.modelContext) private var context

    @State private var formatTag: FormatTag?
    @State private var conditionMin: CardCondition?
    @State private var targetPriceText: String = ""
    @State private var qtyNeed: Int = 1
    @State private var notes: String = ""
    @State private var addError: String? = nil

    /// Format options filtered by the printing's legality map.
    private var formatOptions: [FormatTag] {
        getFormatOptions(legalitiesJSON: normalized.legalities)
    }

    /// qty_need range (1..4 normally, 1..30 for basic lands).
    private var qtyOptions: [Int] {
        qtyNeedOptionsFor(normalized.nameEn)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cardPreview
                formSection
                if let addError {
                    Text(addError)
                        .font(.appCaption())
                        .foregroundStyle(Color.destructive)
                }
                addButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.bgCanvas)
        .navigationTitle("詳細を入力")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Default the format picker to whatever Scryfall says this printing
            // is legal in first (standard > pioneer > modern > ... > other).
            formatTag = getDefaultFormatTag(legalitiesJSON: normalized.legalities)
        }
    }

    // MARK: - Preview

    private var cardPreview: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.separator)
                .aspectRatio(5.0/7.0, contentMode: .fit)
                .frame(width: 90)
                .overlay {
                    if let url = normalized.imageURL {
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFill()
                            } else {
                                ProgressView().tint(Color.textTertiary)
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(normalized.nameJa ?? normalized.nameEn)
                    .font(.appHeadline())
                    .foregroundStyle(Color.textPrimary)
                // Show the English original line only when the headline
                // above is the JA printed_name — otherwise the EN line is
                // already serving as the headline.
                if normalized.nameJa != nil {
                    Text(normalized.nameEn)
                        .font(.appCaption())
                        .foregroundStyle(Color.textSecondary)
                }
                Text("\(normalized.setCode.uppercased()) #\(normalized.collectorNumber) · \(normalized.lang.uppercased())")
                    .font(.appCaption())
                    .foregroundStyle(Color.textTertiary)
                Text(finishLabel(normalized.finish, promoTypesJSON: normalized.promoTypes))
                    .font(.appCaption().weight(.medium))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Form fields

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Format
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel("Format")
                Picker("Format", selection: $formatTag) {
                    Text("— 未設定 —").tag(FormatTag?.none)
                    ForEach(formatOptions) { tag in
                        Text(tag.label).tag(FormatTag?.some(tag))
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.textPrimary)
            }

            // Condition floor
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel("最低コンディション")
                Picker("Condition", selection: $conditionMin) {
                    Text("— 問わない —").tag(CardCondition?.none)
                    ForEach(CardCondition.allCases) { c in
                        Text(c.rawValue).tag(CardCondition?.some(c))
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.textPrimary)
            }

            // Target price
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel("希望価格 (¥)")
                TextField("例: 300", text: $targetPriceText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            // Qty needed
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel("必要枚数")
                Picker("Qty Need", selection: $qtyNeed) {
                    ForEach(qtyOptions, id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.textPrimary)
            }

            // Notes
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel("メモ")
                TextField("例: Old-frame 優先", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.5)
            .textCase(.uppercase)
            .foregroundStyle(Color.textTertiary)
    }

    // MARK: - Add CTA

    private var addButton: some View {
        Button(action: commit) {
            Text("ウィッシュリストに追加")
                .font(.appBody().weight(.semibold))
                .foregroundStyle(Color.bgCanvas)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.accentInk))
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - Commit

    private func commit() {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedPrice = Int(targetPriceText.filter { $0.isNumber })

        // Upsert the card row first (so the WishlistItem's FK lands).
        let card = Card.upsert(normalized, in: context)

        // Insert a new wishlist row. Web semantics: no dedupe at the add
        // page level (the same scryfall_id can sit under different format
        // buckets). Dedupe lives in the import path only.
        let item = WishlistItem(
            card: card,
            formatTag: formatTag?.rawValue,
            conditionMin: conditionMin,
            targetPrice: parsedPrice,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            qtyHave: 0,
            qtyNeed: qtyNeed
        )
        context.insert(item)

        do {
            try context.save()
            // Haptic feedback so the add lands in the user's body too.
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onAdded()
        } catch {
            addError = "保存に失敗しました: \(error.localizedDescription)"
        }
    }
}
