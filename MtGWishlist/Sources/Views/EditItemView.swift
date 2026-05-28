import SwiftData
import SwiftUI

/// Detail / edit screen pushed when the user taps a wishlist row. Mirrors
/// the Web `/item/[id]/edit/EditForm.tsx` form: same fields, same picker
/// vocabulary, same destructive-action footer.
///
/// Edits are buffered in local `@State` until the user taps Save — same as
/// the Web build, so accidental field touches don't immediately persist
/// (gives "Cancel by backing out" semantics even though SwiftData would
/// otherwise auto-track property writes).
struct EditItemView: View {
    let item: WishlistItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var formatTag: FormatTag?
    @State private var conditionMin: CardCondition?
    @State private var targetPriceText: String = ""
    @State private var qtyHave: Int = 0
    @State private var qtyNeed: Int = 1
    @State private var notes: String = ""

    @State private var showDeleteAlert = false
    @State private var saveError: String? = nil

    private var formatOptions: [FormatTag] {
        getFormatOptions(legalitiesJSON: item.card.legalities)
    }

    private var haveOptions: [Int] {
        qtyHaveOptionsFor(item.card.nameEn)
    }

    private var needOptions: [Int] {
        qtyNeedOptionsFor(item.card.nameEn)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                cardPreview
                formSection
                if let saveError {
                    Text(saveError)
                        .font(.appCaption())
                        .foregroundStyle(Color.destructive)
                }
                deleteButton
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(Color.bgCanvas)
        .navigationTitle("編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("保存", action: save)
                    .foregroundStyle(Color.textPrimary)
                    .font(.appBody().weight(.semibold))
            }
        }
        .onAppear(perform: loadFromItem)
        .alert("このアイテムを削除しますか？", isPresented: $showDeleteAlert) {
            Button("削除", role: .destructive, action: delete)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("\(item.card.nameJa ?? item.card.nameEn) を wishlist から取り除きます。元に戻せません。")
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
                    if let url = item.card.imageURL {
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
                Text(item.card.nameJa ?? item.card.nameEn)
                    .font(.appHeadline())
                    .foregroundStyle(Color.textPrimary)
                if item.card.nameJa != nil {
                    Text(item.card.nameEn)
                        .font(.appCaption())
                        .foregroundStyle(Color.textSecondary)
                }
                Text("\(item.card.setCode.uppercased()) #\(item.card.collectorNumber) · \((item.card.lang ?? "").uppercased())")
                    .font(.appCaption())
                    .foregroundStyle(Color.textTertiary)
                Text(finishLabel(item.card.finish, promoTypesJSON: item.card.promoTypes))
                    .font(.appCaption().weight(.medium))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: - Form fields

    private var formSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            field("Format") {
                Picker("Format", selection: $formatTag) {
                    Text("— 未設定 —").tag(FormatTag?.none)
                    ForEach(formatOptions) { tag in
                        Text(tag.label).tag(FormatTag?.some(tag))
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.textPrimary)
            }

            field("最低コンディション") {
                Picker("Condition", selection: $conditionMin) {
                    Text("— 問わない —").tag(CardCondition?.none)
                    ForEach(CardCondition.allCases) { c in
                        Text(c.rawValue).tag(CardCondition?.some(c))
                    }
                }
                .pickerStyle(.menu)
                .tint(Color.textPrimary)
            }

            field("希望価格 (¥)") {
                TextField("例: 300", text: $targetPriceText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 12) {
                field("所持枚数") {
                    Picker("Qty Have", selection: $qtyHave) {
                        ForEach(haveOptions, id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.textPrimary)
                }
                field("必要枚数") {
                    Picker("Qty Need", selection: $qtyNeed) {
                        ForEach(needOptions, id: \.self) { n in
                            Text("\(n)").tag(n)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Color.textPrimary)
                }
            }

            field("メモ") {
                TextField("例: Old-frame 優先", text: $notes, axis: .vertical)
                    .lineLimit(2...5)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    /// Shared label+content scaffold for a single edit field. Keeps the
    /// "small uppercase label above each control" rhythm consistent with
    /// the AddCardForm visual language.
    @ViewBuilder
    private func field<Content: View>(
        _ label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .textCase(.uppercase)
                .foregroundStyle(Color.textTertiary)
            content()
        }
    }

    // MARK: - Delete CTA

    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteAlert = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("ウィッシュリストから削除")
                    .font(.appBody().weight(.semibold))
            }
            .foregroundStyle(Color.destructive)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                Capsule().strokeBorder(Color.destructive.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    // MARK: - State sync

    private func loadFromItem() {
        formatTag = item.formatTag.flatMap(FormatTag.init(rawValue:))
        conditionMin = item.conditionMin
        targetPriceText = item.targetPrice.map(String.init) ?? ""
        qtyHave = item.qtyHave
        qtyNeed = item.qtyNeed
        notes = item.notes ?? ""
    }

    private func save() {
        item.formatTag = formatTag?.rawValue
        item.conditionMin = conditionMin
        item.targetPrice = Int(targetPriceText.filter { $0.isNumber })
        item.qtyHave = qtyHave
        item.qtyNeed = qtyNeed
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        item.notes = trimmed.isEmpty ? nil : trimmed
        do {
            try context.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            saveError = "保存に失敗しました: \(error.localizedDescription)"
        }
    }

    private func delete() {
        context.delete(item)
        try? context.save()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        dismiss()
    }
}
