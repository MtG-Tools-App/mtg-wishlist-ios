import Foundation

/// Basic land detection by English card name. Mirrors `src/lib/format/basicLand.ts`
/// in the Web codebase.
///
/// The qty pickers elsewhere in the app default to 1–4 (the realistic range
/// for ~all non-basic cards), but a single basic land in a deck routinely
/// runs 18–28 copies. We expand the qty_need range to 1–30 for these cards.
private let BASIC_LAND_NAMES: Set<String> = [
    "Plains", "Island", "Swamp", "Mountain", "Forest", "Wastes",
    "Snow-Covered Plains", "Snow-Covered Island", "Snow-Covered Swamp",
    "Snow-Covered Mountain", "Snow-Covered Forest",
]

func isBasicLand(_ nameEn: String) -> Bool {
    BASIC_LAND_NAMES.contains(nameEn)
}

/// 1..4 for normal cards, 1..30 for basic lands. `qty_need = 0` is excluded
/// — "I want 0 of this card" never reflects intent.
func qtyNeedOptionsFor(_ nameEn: String) -> [Int] {
    isBasicLand(nameEn) ? Array(1...30) : Array(1...4)
}

/// 0..4 for normal cards, 0..30 for basic lands. Used for `qty_have` (where
/// owning zero is the norm starting point).
func qtyHaveOptionsFor(_ nameEn: String) -> [Int] {
    isBasicLand(nameEn) ? Array(0...30) : Array(0...4)
}
