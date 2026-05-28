import SwiftUI

/// Tiny outlined chip rendered in the top-right of a WishlistCard for
/// finishes/treatments that deserve calling out (Foil / Etched / Oil Slick
/// / Surge Foil / Textured). Visual styling mirrors the Web version's
/// `text-[8px] px-1 py-0.5 rounded-full border` chip — small, restrained,
/// and never the dominant element.
struct FoilBadge: View {
    let finish: CardFinish
    /// JSON-encoded promo_types array from `Card.promoTypes`, may be nil.
    let promoTypesJSON: String?

    var body: some View {
        Text(finishLabel(finish, promoTypesJSON: promoTypesJSON).uppercased())
            .font(.system(size: 9, weight: .semibold, design: .default))
            .tracking(0.5)
            .foregroundStyle(Color.textSecondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(
                Capsule().strokeBorder(Color.separator, lineWidth: 0.5)
            )
    }
}
