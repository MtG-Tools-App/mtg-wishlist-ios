import Foundation

// MARK: - Frame era / special-print classification
//
// Port of the matchesFrame / isSpecialPrint logic from
// `src/app/add/AddPageClient.tsx`. The four frame buckets stay mutually
// exclusive (新枠 / 旧枠 / 白枠 / 特殊枠) so the same printing never appears
// under two filters.

/// Old-frame tags. Treated as "旧枠" everywhere unless overridden by a
/// `SPECIAL_SET_TYPES` membership (Un-set / SLD retro frame).
let OLD_FRAMES: Set<String> = ["1993", "1997"]

/// Set types that automatically promote a printing to 特殊枠 regardless of
/// frame era — SLD/SLC (box), Un-sets (funny), FTV/spellbook/masterpiece,
/// memorabilia anniversaries.
let SPECIAL_SET_TYPES: Set<String> = [
    "box", "funny", "memorabilia",
    "from_the_vault", "spellbook", "masterpiece",
]

/// Curated whitelist of `promo_types` that signal visual distinction. Plain
/// stamps (`stamped`, `arenaleague`, `fnm`, `judgegift`) are intentionally
/// out — they sit on otherwise standard art and don't belong in 特殊枠.
let VISUAL_PROMO_TYPES: Set<String> = [
    "oilslick", "surgefoil", "raisedfoil", "neonink", "textured",
    "halofoil", "silverfoil", "doublerainbow", "embossed",
    "stepandcompleat", "thick", "serialized",
    "godzillaseries", "doctor", "dracula", "draculaseries",
    "walkingdead", "stranger", "jpwalker", "universesbeyond", "ampersand",
    "boosterfun", "buyabox", "bringafriend", "concept",
]

/// Frame effects considered visually distinct. Generic decorations like
/// "legendary" or "snow" are out — they'd drag in every legendary creature
/// or snow basic.
let VISUAL_FRAME_EFFECTS: Set<String> = [
    "showcase", "extendedart", "etched", "inverted", "shatteredglass",
    "fullart", "borderless", "textured", "nyxtouched", "colorshifted",
]

/// Returns true if this printing is visually special enough to live in 特殊枠
/// rather than 新枠/旧枠. Single source of truth for the FrameFilter UI.
func isSpecialPrint(_ card: NormalizedCard) -> Bool {
    // SPECIAL_SET_TYPES wins absolutely (Un-set / SLD retro frame).
    if let setType = card.setType, SPECIAL_SET_TYPES.contains(setType) {
        return true
    }
    // Old-frame prints from regular sets belong in 旧枠 (APAC / Guru / etc.).
    if let frame = card.frame, OLD_FRAMES.contains(frame) {
        return false
    }
    if card.borderColor == "borderless" { return true }
    if card.fullArt == true { return true }
    if card.textless == true { return true }
    if card.frame == "future" { return true }

    if let promoJSON = card.promoTypes,
       let promo = decodeStringArrayLocal(promoJSON),
       promo.contains(where: VISUAL_PROMO_TYPES.contains) {
        return true
    }
    if let effectsJSON = card.frameEffects,
       let effects = decodeStringArrayLocal(effectsJSON),
       effects.contains(where: VISUAL_FRAME_EFFECTS.contains) {
        return true
    }
    return false
}

private func decodeStringArrayLocal(_ json: String) -> [String]? {
    guard let data = json.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode([String].self, from: data)
}

// MARK: - User-facing filter enums

enum LangFilter: String, CaseIterable, Identifiable {
    case ja, en, other, all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .ja: return "日本語"
        case .en: return "英語"
        case .other: return "他言語"
        case .all: return "ALL"
        }
    }
    func matches(_ card: NormalizedCard) -> Bool {
        switch self {
        case .all: return true
        case .ja: return card.lang == "ja"
        case .en: return card.lang == "en"
        case .other: return card.lang != "ja" && card.lang != "en"
        }
    }
}

enum FinishFilter: String, CaseIterable, Identifiable {
    case nonfoil, foil
    var id: String { rawValue }
    var label: String {
        switch self {
        case .nonfoil: return "Non Foil"
        case .foil: return "Foil"
        }
    }
    func matches(_ card: NormalizedCard) -> Bool {
        switch self {
        case .nonfoil: return card.finish == .nonfoil
        case .foil:    return card.finish == .foil || card.finish == .etched
        }
    }
}

enum FrameFilter: String, CaseIterable, Identifiable {
    case modern, old, white, special, all
    var id: String { rawValue }
    var label: String {
        switch self {
        case .modern: return "新枠"
        case .old:    return "旧枠"
        case .white:  return "白枠"
        case .special: return "特殊枠"
        case .all:    return "ALL"
        }
    }
    func matches(_ card: NormalizedCard) -> Bool {
        switch self {
        case .all: return true
        case .white: return card.borderColor == "white"
        case .special: return isSpecialPrint(card)
        case .modern:
            if isSpecialPrint(card) { return false }
            return card.frame == "2015" || card.frame == "2003"
        case .old:
            if isSpecialPrint(card) { return false }
            return card.frame == "1993" || card.frame == "1997"
        }
    }
}
