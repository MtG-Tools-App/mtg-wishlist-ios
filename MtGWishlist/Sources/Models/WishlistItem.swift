import Foundation
import SwiftData

/// One wishlist row — a user's intent to acquire a specific Card under a
/// specific format/condition/price target. Matches the web `wishlist_items`
/// table 1:1.
///
/// The same `Card` may appear in multiple WishlistItems (e.g., one entry for
/// Modern, one for Legacy), so the relationship is many-to-one not one-to-one.
@Model
final class WishlistItem {
    var card: Card

    /// nil = no format assigned ("Other" bucket). Matches Web's nullable column.
    var formatTag: String?

    /// `CardCondition.rawValue` or nil. Use `conditionMin` to round-trip.
    var conditionMinRaw: String?

    /// Yen, integer (matches Web's `target_price INTEGER`).
    var targetPrice: Int?

    var notes: String?
    var qtyHave: Int
    var qtyNeed: Int
    var createdAt: Date

    /// Cascade: deleting a WishlistItem drops its price log history (which is
    /// only meaningful in the context of the item).
    @Relationship(deleteRule: .cascade, inverse: \PriceLog.wishlistItem)
    var priceLogs: [PriceLog] = []

    init(
        card: Card,
        formatTag: String? = nil,
        conditionMin: CardCondition? = nil,
        targetPrice: Int? = nil,
        notes: String? = nil,
        qtyHave: Int = 0,
        qtyNeed: Int = 1,
        createdAt: Date = .now
    ) {
        self.card = card
        self.formatTag = formatTag
        self.conditionMinRaw = conditionMin?.rawValue
        self.targetPrice = targetPrice
        self.notes = notes
        self.qtyHave = qtyHave
        self.qtyNeed = qtyNeed
        self.createdAt = createdAt
    }

    // MARK: - Convenience accessors

    var conditionMin: CardCondition? {
        get { conditionMinRaw.flatMap(CardCondition.init(rawValue:)) }
        set { conditionMinRaw = newValue?.rawValue }
    }

    /// "Satisfied" flag for the wishlist card UI — same semantic as the Web's
    /// inline qty editor: green checkmark when `qty_have >= qty_need`.
    var isSatisfied: Bool { qtyHave >= qtyNeed }

    /// Most recent price log (by `loggedAt`), if any. Wishlist row UI shows
    /// this as the headline "latest price · shop · date" line.
    var latestPriceLog: PriceLog? {
        priceLogs.max { $0.loggedAt < $1.loggedAt }
    }
}
