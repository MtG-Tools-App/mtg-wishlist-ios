import Foundation

/// In-memory shape produced by `normalize(_:)`. Each row represents one
/// (Scryfall printing × finish) tuple — Lightning Bolt M10 with finishes
/// `["nonfoil", "foil"]` becomes two NormalizedCards with synthetic ids
/// `<uuid>:nonfoil` and `<uuid>:foil`.
///
/// This is the shape the AddCardView's search results render. When the user
/// taps Add, `Card.upsert(normalized:context:)` translates it into the
/// persistent SwiftData `Card` model.
struct NormalizedCard: Identifiable, Hashable {
    /// `{scryfall_uuid}:{finish}` — unique per (printing × finish).
    let scryfallId: String
    let nameEn: String
    let nameJa: String?
    let setCode: String
    let collectorNumber: String
    let lang: String
    let finish: CardFinish
    let imageURL: URL?
    let oracleId: String
    let cachedAt: Date
    /// JSON-encoded legality map; nil for legacy rows.
    let legalities: String?
    let frame: String?
    let borderColor: String?
    /// JSON-encoded frame_effects array; nil if none.
    let frameEffects: String?
    let fullArt: Bool?
    let textless: Bool?
    let setType: String?
    /// JSON-encoded promo_types array; nil if none.
    let promoTypes: String?

    var id: String { scryfallId }
}

// MARK: - Normalization

/// Expands a single Scryfall card into one NormalizedCard per available
/// finish. Empty `finishes` falls back to `nonfoil` so prints with missing
/// data still surface in search results.
func normalize(_ card: ScryfallCard) -> [NormalizedCard] {
    let nameEn = card.name

    // printed_name is only present on non-English prints. For DFCs the
    // front face carries it (index 0).
    let nameJa = card.printedName ?? card.cardFaces?.first?.printedName

    // image_uris lives at the top level for single-faced prints, per-face
    // for double-faced prints. Fall back to the front face.
    let imageString = card.imageUris?.normal ?? card.cardFaces?.first?.imageUris?.normal
    let imageURL = imageString.flatMap(URL.init(string:))

    let finishes: [String] = card.finishes.isEmpty ? ["nonfoil"] : card.finishes
    let resolvedFinishes = finishes.compactMap(CardFinish.init(rawValue:))

    let legalitiesJSON = encodeJSON(card.legalities)
    let frameEffectsJSON = encodeJSONArray(card.frameEffects)
    let promoTypesJSON = encodeJSONArray(card.promoTypes)
    let now = Date()

    return resolvedFinishes.map { finish in
        NormalizedCard(
            scryfallId: "\(card.id):\(finish.rawValue)",
            nameEn: nameEn,
            nameJa: nameJa,
            setCode: card.set,
            collectorNumber: card.collectorNumber,
            lang: card.lang,
            finish: finish,
            imageURL: imageURL,
            oracleId: card.oracleId,
            cachedAt: now,
            legalities: legalitiesJSON,
            frame: card.frame,
            borderColor: card.borderColor,
            frameEffects: frameEffectsJSON,
            fullArt: card.fullArt,
            textless: card.textless,
            setType: card.setType,
            promoTypes: promoTypesJSON
        )
    }
}

// MARK: - JSON helpers

/// Encodes a [String:String] map (legalities) to a JSON string column.
private func encodeJSON(_ map: [String: String]?) -> String? {
    guard let map, !map.isEmpty else { return nil }
    let data = try? JSONSerialization.data(withJSONObject: map, options: [.sortedKeys])
    return data.flatMap { String(data: $0, encoding: .utf8) }
}

/// Encodes a [String] array (frame_effects / promo_types) to a JSON string.
private func encodeJSONArray(_ arr: [String]?) -> String? {
    guard let arr, !arr.isEmpty else { return nil }
    let data = try? JSONSerialization.data(withJSONObject: arr, options: [])
    return data.flatMap { String(data: $0, encoding: .utf8) }
}

/// Extracts the bare Scryfall UUID from a synthetic `{uuid}:{finish}` id.
func extractScryfallUuid(_ syntheticId: String) -> String {
    guard let colonIndex = syntheticId.lastIndex(of: ":") else { return syntheticId }
    return String(syntheticId[..<colonIndex])
}
