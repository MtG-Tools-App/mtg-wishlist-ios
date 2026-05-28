import Foundation
import SwiftData

/// One observed price point for a specific WishlistItem. Matches the web
/// `price_logs` table 1:1.
///
/// Stored as device-local data only — the JSON backup bridge (Phase 6)
/// intentionally excludes price logs since they represent "what the market
/// looked like at time T" rather than "what the user wants," which is the
/// scope the backup is meant to round-trip.
@Model
final class PriceLog {
    /// Optional inverse: SwiftData auto-clears this on cascade delete from
    /// the WishlistItem side (see `WishlistItem.priceLogs` delete rule).
    var wishlistItem: WishlistItem?

    /// Yen, integer (matches Web's `price INTEGER NOT NULL`).
    var price: Int

    /// `PriceLogShop.rawValue`. Use `shop` to round-trip.
    var shopRaw: String

    /// `CardCondition.rawValue` or nil. Use `conditionActual` to round-trip.
    /// "Actual" because this records *what the shop is selling*, not the
    /// user's minimum acceptance floor (which is `WishlistItem.conditionMin`).
    var conditionActualRaw: String?

    /// String storage for flexibility; `urlValue` returns the parsed URL.
    var url: String?

    /// Whether the listing was in stock when logged. Lets the wishlist
    /// surface "sold out" badges.
    var available: Bool

    var loggedAt: Date

    init(
        wishlistItem: WishlistItem,
        price: Int,
        shop: PriceLogShop,
        conditionActual: CardCondition? = nil,
        url: String? = nil,
        available: Bool = true,
        loggedAt: Date = .now
    ) {
        self.wishlistItem = wishlistItem
        self.price = price
        self.shopRaw = shop.rawValue
        self.conditionActualRaw = conditionActual?.rawValue
        self.url = (url?.isEmpty == true) ? nil : url
        self.available = available
        self.loggedAt = loggedAt
    }

    // MARK: - Convenience accessors

    var shop: PriceLogShop {
        get { PriceLogShop(rawValue: shopRaw) ?? .other }
        set { shopRaw = newValue.rawValue }
    }

    var conditionActual: CardCondition? {
        get { conditionActualRaw.flatMap(CardCondition.init(rawValue:)) }
        set { conditionActualRaw = newValue?.rawValue }
    }

    var urlValue: URL? {
        url.flatMap(URL.init(string:))
    }
}
