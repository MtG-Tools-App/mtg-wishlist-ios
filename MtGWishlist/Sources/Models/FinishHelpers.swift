import Foundation

/// Display string for a printing's finish, including the promo-specific
/// variants (Oil Slick / Surge Foil / Textured) that the user wants
/// surfaced as labels. Mirrors `src/lib/format/finish.ts` in the Web
/// codebase so the JSON backup round-trips with matching display text.
func finishLabel(_ finish: CardFinish, promoTypesJSON: String?) -> String {
    let promo = decodeStringArray(promoTypesJSON)
    if promo.contains("oilslick") { return "Oil Slick" }
    if promo.contains("surgefoil") { return "Surge Foil" }
    if promo.contains("textured") { return "Textured" }
    switch finish {
    case .nonfoil: return "Non Foil"
    case .foil:    return "Foil"
    case .etched:  return "Etched"
    }
}

/// Whether the WishlistCard view should render the foil badge chip at all.
/// Plain non-foil printings don't get a badge — only the actively-special
/// finishes do (avoids visual clutter on the most common case).
func hasFoilBadge(_ finish: CardFinish, promoTypesJSON: String?) -> Bool {
    if finish == .foil || finish == .etched { return true }
    let promo = decodeStringArray(promoTypesJSON)
    return promo.contains("oilslick")
        || promo.contains("surgefoil")
        || promo.contains("textured")
}

/// Tiny JSON-array decoder. We persist `promo_types` and `frame_effects` as
/// JSON-encoded strings (matching the Web SQL representation) so that the
/// SwiftData schema doesn't have to model arbitrary string arrays as
/// relations. Decode lazily at display time.
private func decodeStringArray(_ json: String?) -> [String] {
    guard let json, let data = json.data(using: .utf8) else { return [] }
    return (try? JSONDecoder().decode([String].self, from: data)) ?? []
}
