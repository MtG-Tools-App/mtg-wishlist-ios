import Foundation
import SwiftData

extension Card {
    /// Insert-or-update a Card row keyed by `scryfallId`. Mirrors the Web
    /// `INSERT INTO cards ... ON CONFLICT(scryfall_id) DO UPDATE` pattern.
    ///
    /// Volatile fields (anything Scryfall could change between fetches —
    /// JA name, legalities, frame metadata, promo_types, cached_at) are
    /// overwritten on every upsert so we drift toward fresh data.
    /// Identity fields (scryfall_id, set_code, collector_number, finish)
    /// stay pinned by definition.
    @discardableResult
    static func upsert(
        _ normalized: NormalizedCard,
        in context: ModelContext
    ) -> Card {
        let id = normalized.scryfallId
        let descriptor = FetchDescriptor<Card>(
            predicate: #Predicate { $0.scryfallId == id }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.nameEn = normalized.nameEn
            existing.nameJa = normalized.nameJa
            existing.imageURL = normalized.imageURL
            existing.cachedAt = .now
            existing.legalities = normalized.legalities
            existing.lang = normalized.lang
            existing.frame = normalized.frame
            existing.borderColor = normalized.borderColor
            existing.frameEffects = normalized.frameEffects
            existing.setType = normalized.setType
            existing.promoTypes = normalized.promoTypes
            return existing
        }
        let new = Card(
            scryfallId: normalized.scryfallId,
            nameEn: normalized.nameEn,
            nameJa: normalized.nameJa,
            setCode: normalized.setCode,
            collectorNumber: normalized.collectorNumber,
            finish: normalized.finish,
            imageURL: normalized.imageURL,
            oracleId: normalized.oracleId,
            cachedAt: .now,
            legalities: normalized.legalities,
            lang: normalized.lang,
            frame: normalized.frame,
            borderColor: normalized.borderColor,
            frameEffects: normalized.frameEffects,
            setType: normalized.setType,
            promoTypes: normalized.promoTypes
        )
        context.insert(new)
        return new
    }
}
