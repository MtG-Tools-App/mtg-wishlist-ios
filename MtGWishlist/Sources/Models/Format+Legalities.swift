import Foundation

/// Helpers that read the JSON-encoded `legalities` map (as Scryfall returns
/// it) to pick a sensible default `format_tag` for a printing and to filter
/// the format picker dropdown. Mirrors `getDefaultFormatTag` /
/// `getFormatOptions` in the Web `src/lib/format/formats.ts`.

/// Returns the first legal format from FormatTag.allCases (excluding
/// `.other`), or `.other` if none are legal, or `nil` if legalities is
/// missing/unparseable. Used to pre-fill the format picker when the user
/// taps Add on a search result.
func getDefaultFormatTag(legalitiesJSON: String?) -> FormatTag? {
    guard let legalitiesJSON,
          let map = decodeLegalities(legalitiesJSON) else { return nil }
    for tag in FormatTag.allCases where tag != .other {
        if map[tag.rawValue] == "legal" { return tag }
    }
    return .other
}

/// Filters FormatTag.allCases down to the formats this printing is actually
/// legal in (plus `.other` which is always present as an escape hatch).
/// Used by the format picker UI so users don't accidentally tag a banned
/// card as Standard.
func getFormatOptions(legalitiesJSON: String?) -> [FormatTag] {
    guard let legalitiesJSON,
          let map = decodeLegalities(legalitiesJSON) else {
        return FormatTag.allCases
    }
    return FormatTag.allCases.filter { tag in
        tag == .other || map[tag.rawValue] == "legal"
    }
}

private func decodeLegalities(_ json: String) -> [String: String]? {
    guard let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode([String: String].self, from: data)
}
