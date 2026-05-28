import Foundation

/// Mirrors the `finish` CHECK constraint from the web SQL schema.
/// Scryfall's three finish kinds — same source-of-truth used to compose the
/// synthetic `scryfall_id` (`{uuid}:{finish}`).
enum CardFinish: String, Codable, CaseIterable, Identifiable {
    case nonfoil
    case foil
    case etched

    var id: String { rawValue }
}

/// Wishlist item's "I'll accept a copy at this condition or better" floor.
/// Mirrors `condition_min` CHECK constraint in the web SQL schema.
enum CardCondition: String, Codable, CaseIterable, Identifiable {
    case NM
    case EX
    case GD

    var id: String { rawValue }
}

/// Shops the user logs observed prices from. Matches `LogPriceSchema.shop`
/// enum in the web Zod schema so JSON round-trips stay clean.
enum PriceLogShop: String, Codable, CaseIterable, Identifiable {
    case hareruya
    case bigmagic
    case cardrush
    case surugaya
    case mercari
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hareruya: return "晴れる屋"
        case .bigmagic: return "BIG MAGIC"
        case .cardrush: return "カードラッシュ"
        case .surugaya: return "駿河屋"
        case .mercari: return "メルカリ"
        case .other:    return "その他"
        }
    }
}
