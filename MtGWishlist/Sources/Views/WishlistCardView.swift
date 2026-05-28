import SwiftUI

/// A single wishlist row rendered as a tall card in the grid: image on top
/// (5:7 aspect to match the MTG card frame), then name (JA-first with EN
/// fallback), price/qty line, and a meta row (set code + collector number +
/// optional condition floor).
///
/// Visual reference: `src/components/WishlistContent.tsx` WishlistCard
/// function in the Web codebase. The data fields render in the same order
/// so a user familiar with the Web build feels at home on iOS.
struct WishlistCardView: View {
    let item: WishlistItem

    /// Sold-out signal: the latest price log on this item is marked
    /// `available == false`. Carries opacity to gray the row out, same
    /// affordance as the Web build's `soldOut ? "opacity-60" : ""`.
    private var soldOut: Bool {
        guard let latest = item.latestPriceLog else { return false }
        return latest.available == false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardImage
                .overlay(alignment: .topTrailing) {
                    if hasFoilBadge(item.card.finish, promoTypesJSON: item.card.promoTypes) {
                        FoilBadge(
                            finish: item.card.finish,
                            promoTypesJSON: item.card.promoTypes
                        )
                        .padding(6)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.card.nameJa ?? item.card.nameEn)
                    .font(.appCaption().weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.top, 8)

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(targetPriceText)
                        .font(.appCaption().weight(.medium))
                        .foregroundStyle(Color.textPrimary)
                        .monospacedDigit()

                    Text("\(item.qtyHave)/\(item.qtyNeed)")
                        .font(.appCaption())
                        .foregroundStyle(item.isSatisfied ? .green : Color.accentSignature)
                        .monospacedDigit()
                }

                Text(metaText)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
        .opacity(soldOut ? 0.6 : 1.0)
    }

    // MARK: - Image

    @ViewBuilder
    private var cardImage: some View {
        // 5:7 is the standard MTG card aspect. Use a clipped RoundedRectangle
        // backdrop so missing image URLs (Phase 2 mostly) still render a
        // pleasant cream-tinted placeholder rather than a void.
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.separator)
            .aspectRatio(5.0/7.0, contentMode: .fit)
            .overlay {
                if let url = item.card.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        case .empty:
                            ProgressView().tint(Color.textTertiary)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundStyle(Color.textTertiary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                        .foregroundStyle(Color.textTertiary)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Text helpers

    private var targetPriceText: String {
        guard let p = item.targetPrice else { return "—" }
        return "¥" + p.formatted(.number.locale(Locale(identifier: "ja_JP")))
    }

    private var metaText: String {
        var parts: [String] = ["\(item.card.setCode.uppercased()) #\(item.card.collectorNumber)"]
        if let cond = item.conditionMin {
            parts.append(cond.rawValue)
        }
        return parts.joined(separator: " · ")
    }
}
