import SwiftUI

/// A single search result in `AddCardView`'s LazyVGrid. Image + name +
/// set/cn + finish + lang badge — compact enough that the grid stays
/// browsable at 2 columns on iPhone portrait.
///
/// Visually similar to `WishlistCardView` but without the price/qty fields
/// (no wishlist context yet). Tap surfaces the print to the parent for the
/// add-form push.
struct SearchResultCard: View {
    let card: NormalizedCard

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            cardImage
                .overlay(alignment: .topTrailing) {
                    if hasFoilBadge(card.finish, promoTypesJSON: card.promoTypes) {
                        FoilBadge(
                            finish: card.finish,
                            promoTypesJSON: card.promoTypes
                        )
                        .padding(6)
                    }
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(card.nameJa ?? card.nameEn)
                    .font(.appCaption().weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("\(card.setCode.uppercased()) #\(card.collectorNumber)")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textTertiary)
                    Text("·")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.textTertiary)
                    Text(card.lang.uppercased())
                        .font(.system(size: 10).weight(.semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .lineLimit(1)
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private var cardImage: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.separator)
            .aspectRatio(5.0/7.0, contentMode: .fit)
            .overlay {
                if let url = card.imageURL {
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
}
