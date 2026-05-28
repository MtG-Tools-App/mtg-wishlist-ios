import Foundation
import SwiftData

/// Placeholder seed data so Phase 2 (read-only wishlist UI) has something
/// to render before Phase 3 introduces Scryfall search-add. Triggered
/// manually from the empty-state button — never auto-runs, so a user who
/// imports a real backup never sees these fake rows.
///
/// The card UUIDs / image URLs / oracle IDs / set codes here are pulled
/// from actual Scryfall responses (verified at seed authoring time) so
/// `AsyncImage` resolves to real card art in the simulator.
enum SeedData {
    static func insertSamples(into context: ModelContext) {
        let now = Date()

        // 1. Lightning Bolt — 2X2 reprint, Modern staple
        let bolt = Card(
            scryfallId: "f29ba16f-c8fb-42fe-aabf-87089cb214a7:nonfoil",
            nameEn: "Lightning Bolt",
            nameJa: "稲妻",
            setCode: "2x2",
            collectorNumber: "117",
            finish: .nonfoil,
            imageURL: URL(string: "https://cards.scryfall.io/normal/front/f/2/f29ba16f-c8fb-42fe-aabf-87089cb214a7.jpg?1673147852"),
            oracleId: "4457ed35-7c10-48c8-9776-456485fdf070",
            lang: "en",
            frame: "2015",
            borderColor: "black",
            setType: "masters"
        )
        context.insert(bolt)
        context.insert(WishlistItem(
            card: bolt, formatTag: FormatTag.modern.rawValue,
            conditionMin: .NM, targetPrice: 300,
            notes: "playset 揃えたい", qtyHave: 2, qtyNeed: 4,
            createdAt: now
        ))

        // 2. Sol Ring CMR — has JA print, regular frame Commander staple
        let solRing = Card(
            scryfallId: "58b26011-e103-45c4-a253-900f4e6b2eeb:nonfoil",
            nameEn: "Sol Ring",
            nameJa: "太陽の指輪",
            setCode: "cmr",
            collectorNumber: "472",
            finish: .nonfoil,
            imageURL: URL(string: "https://cards.scryfall.io/normal/front/5/8/58b26011-e103-45c4-a253-900f4e6b2eeb.jpg?1627501347"),
            oracleId: "6ad8011d-3471-4369-9d68-b264cc027487",
            lang: "en",
            frame: "2015",
            borderColor: "black",
            setType: "draft_innovation"
        )
        context.insert(solRing)
        context.insert(WishlistItem(
            card: solRing, formatTag: FormatTag.other.rawValue,
            targetPrice: 600, qtyHave: 0, qtyNeed: 1,
            createdAt: now
        ))

        // 3. Brainstorm STA — borderless showcase ← exercises FoilBadge
        let brainstormFoil = Card(
            scryfallId: "11d27509-07c2-4445-a1d5-e56523fb8566:foil",
            nameEn: "Brainstorm",
            nameJa: "渦巻く知識",
            setCode: "sta",
            collectorNumber: "13",
            finish: .foil,
            imageURL: URL(string: "https://cards.scryfall.io/normal/front/1/1/11d27509-07c2-4445-a1d5-e56523fb8566.jpg?1623592140"),
            oracleId: "36cd2364-d113-47d1-b2c4-b088d9eb88dd",
            lang: "en",
            frame: "2015",
            borderColor: "borderless",
            frameEffects: "[\"showcase\"]",
            setType: "masterpiece"
        )
        context.insert(brainstormFoil)
        context.insert(WishlistItem(
            card: brainstormFoil, formatTag: FormatTag.legacy.rawValue,
            conditionMin: .NM, targetPrice: 2500,
            qtyHave: 0, qtyNeed: 4,
            createdAt: now
        ))

        // 4. Force of Will EMA — Legacy classic
        let fow = Card(
            scryfallId: "ebc01ab4-d89a-4d25-bf54-6aed33772f4b:nonfoil",
            nameEn: "Force of Will",
            nameJa: "意志の力",
            setCode: "ema",
            collectorNumber: "49",
            finish: .nonfoil,
            imageURL: URL(string: "https://cards.scryfall.io/normal/front/e/b/ebc01ab4-d89a-4d25-bf54-6aed33772f4b.jpg?1580013954"),
            oracleId: "956381ba-6d37-4a8a-846c-bad79222dbee",
            lang: "en",
            frame: "2015",
            borderColor: "black",
            setType: "masters"
        )
        context.insert(fow)
        context.insert(WishlistItem(
            card: fow, formatTag: FormatTag.legacy.rawValue,
            targetPrice: 15000, qtyHave: 0, qtyNeed: 4,
            createdAt: now
        ))

        // 5. Island THB Nyxtouched (full-art) ← exercises full_art + 基本土地 qty range
        let island = Card(
            scryfallId: "acf7b664-3e75-4018-81f6-2a14ab59f258:nonfoil",
            nameEn: "Island",
            nameJa: "島",
            setCode: "thb",
            collectorNumber: "251",
            finish: .nonfoil,
            imageURL: URL(string: "https://cards.scryfall.io/normal/front/a/c/acf7b664-3e75-4018-81f6-2a14ab59f258.jpg?1641306192"),
            oracleId: "b2c6aa39-2d2a-459c-a555-fb48ba993373",
            lang: "en",
            frame: "2015",
            borderColor: "black",
            frameEffects: "[\"fullart\"]",
            setType: "expansion"
        )
        context.insert(island)
        context.insert(WishlistItem(
            card: island, formatTag: FormatTag.modern.rawValue,
            qtyHave: 4, qtyNeed: 12,
            createdAt: now
        ))

        try? context.save()
    }

    /// Deletes every wishlist row + card cache row, for the "reset sample
    /// data" button. SwiftData's cascade rules will sweep PriceLogs along.
    static func wipeAll(in context: ModelContext) {
        try? context.delete(model: WishlistItem.self)
        try? context.delete(model: Card.self)
        try? context.delete(model: PriceLog.self)
        try? context.save()
    }
}
