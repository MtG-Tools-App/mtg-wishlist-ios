import Foundation

// MARK: - Scryfall API response shapes
//
// Subset of the Scryfall Card object actually used by the wishlist. We
// intentionally don't model every field — keeps the decoder fast and
// breakage surface small if Scryfall adds new keys. Field names mirror
// Scryfall's JSON keys via custom CodingKeys so the wire format is
// transparent at the call site.

struct ScryfallImageUris: Decodable {
    let small: String?
    let normal: String?
    let large: String?
}

struct ScryfallCardFace: Decodable {
    let name: String?
    let printedName: String?
    let imageUris: ScryfallImageUris?

    enum CodingKeys: String, CodingKey {
        case name
        case printedName = "printed_name"
        case imageUris = "image_uris"
    }
}

/// One Scryfall printing in its raw on-the-wire form.
struct ScryfallCard: Decodable, Identifiable {
    /// Scryfall UUID — unique per printing, *not* per finish.
    let id: String
    let oracleId: String
    let name: String
    /// Localized printed name; only present for non-English prints.
    let printedName: String?
    /// ISO 639-1.
    let lang: String
    /// Short set code (e.g. "m10").
    let set: String
    let setName: String?
    let collectorNumber: String
    /// Available finish variants for this printing.
    let finishes: [String]
    /// Single-faced prints expose image_uris at the top level.
    let imageUris: ScryfallImageUris?
    /// Double-faced prints expose images per face.
    let cardFaces: [ScryfallCardFace]?
    /// Format legality map ("standard": "legal" | "not_legal" | "banned" | ...)
    let legalities: [String: String]?
    /// MTGO/Arena-only printings have `digital: true`.
    let digital: Bool?
    /// Which client carries this printing — "paper" / "mtgo" / "arena" / "astral"
    let games: [String]?
    let frame: String?
    let borderColor: String?
    let frameEffects: [String]?
    let fullArt: Bool?
    let textless: Bool?
    /// "expansion" / "core" / "promo" / "box" / "memorabilia" / etc.
    let setType: String?
    /// Granular promo tags ("oilslick", "surgefoil", ...). Combined with
    /// `finishes` to surface Oil Slick / Surge Foil / Textured.
    let promoTypes: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case oracleId = "oracle_id"
        case name
        case printedName = "printed_name"
        case lang
        case set
        case setName = "set_name"
        case collectorNumber = "collector_number"
        case finishes
        case imageUris = "image_uris"
        case cardFaces = "card_faces"
        case legalities
        case digital
        case games
        case frame
        case borderColor = "border_color"
        case frameEffects = "frame_effects"
        case fullArt = "full_art"
        case textless
        case setType = "set_type"
        case promoTypes = "promo_types"
    }
}

struct ScryfallSearchResponse: Decodable {
    let object: String
    let totalCards: Int?
    let hasMore: Bool?
    let nextPage: String?
    let data: [ScryfallCard]

    enum CodingKeys: String, CodingKey {
        case object
        case totalCards = "total_cards"
        case hasMore = "has_more"
        case nextPage = "next_page"
        case data
    }
}

struct ScryfallError: Decodable, Error {
    let object: String
    let code: String
    let status: Int
    let details: String
}
