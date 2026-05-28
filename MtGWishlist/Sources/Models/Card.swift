import Foundation
import SwiftData

/// Card row — one per (Scryfall printing × finish) tuple. Matches the web
/// `cards` table 1:1 so `scryfall_id` ("{uuid}:{finish}") can be compared
/// across the JSON backup bridge.
///
/// Note on enum-as-String: SwiftData stores raw `String` for `finish` rather
/// than the `CardFinish` enum directly. The macro doesn't yet support custom
/// enums as stored properties cleanly across all migration scenarios, and
/// the raw column matches the web schema for free.
@Model
final class Card {
    /// Synthetic id: `{scryfall_uuid}:{finish}`. Logically unique per printing
    /// × finish, but `@Attribute(.unique)` cannot be used here: Core Data
    /// refuses uniqueness constraints when a relationship has a mandatory
    /// to-one inverse without a cascade delete rule, and cascading from Card
    /// to WishlistItem would destroy the user's wishlist when a card-cache
    /// row is pruned. The Web schema uses `INSERT ... ON CONFLICT` to enforce
    /// uniqueness at the application layer; we mirror that with an upsert
    /// helper (see `Card.upsert(scryfallId:context:...)` once it lands in
    /// Phase 2). For now, callers must guarantee uniqueness themselves.
    var scryfallId: String

    var nameEn: String
    var nameJa: String?
    var setCode: String
    var collectorNumber: String

    /// `CardFinish.rawValue`. Use the `finish` computed property to round-trip.
    var finishRaw: String

    /// Stored as String to keep SwiftData migrations simple. Use `imageURL`.
    var imageURLString: String?

    var oracleId: String
    var cachedAt: Date

    /// JSON-serialized legality map. The web schema mirrors Scryfall's
    /// `{ standard: "legal" | "not_legal", ... }` payload verbatim.
    var legalities: String?

    var lang: String?
    var frame: String?
    var borderColor: String?

    /// JSON-serialized array of frame_effect strings ("showcase", "extendedart", etc.)
    var frameEffects: String?

    var setType: String?

    /// JSON-serialized array of promo_type strings ("oilslick", "surgefoil", etc.)
    var promoTypes: String?

    /// Inverse of `WishlistItem.card`. Cascade-deleting wishlist items here
    /// would drop the card row too aggressively (same card can sit under
    /// multiple format_tags), so we leave the delete rule `.nullify`.
    @Relationship(deleteRule: .nullify, inverse: \WishlistItem.card)
    var wishlistItems: [WishlistItem] = []

    init(
        scryfallId: String,
        nameEn: String,
        nameJa: String? = nil,
        setCode: String,
        collectorNumber: String,
        finish: CardFinish,
        imageURL: URL? = nil,
        oracleId: String,
        cachedAt: Date = .now,
        legalities: String? = nil,
        lang: String? = nil,
        frame: String? = nil,
        borderColor: String? = nil,
        frameEffects: String? = nil,
        setType: String? = nil,
        promoTypes: String? = nil
    ) {
        self.scryfallId = scryfallId
        self.nameEn = nameEn
        self.nameJa = nameJa
        self.setCode = setCode
        self.collectorNumber = collectorNumber
        self.finishRaw = finish.rawValue
        self.imageURLString = imageURL?.absoluteString
        self.oracleId = oracleId
        self.cachedAt = cachedAt
        self.legalities = legalities
        self.lang = lang
        self.frame = frame
        self.borderColor = borderColor
        self.frameEffects = frameEffects
        self.setType = setType
        self.promoTypes = promoTypes
    }

    // MARK: - Convenience accessors

    var finish: CardFinish {
        get { CardFinish(rawValue: finishRaw) ?? .nonfoil }
        set { finishRaw = newValue.rawValue }
    }

    var imageURL: URL? {
        get { imageURLString.flatMap(URL.init(string:)) }
        set { imageURLString = newValue?.absoluteString }
    }
}
