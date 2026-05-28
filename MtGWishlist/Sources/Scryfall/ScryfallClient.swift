import Foundation

/// Swift port of `src/lib/scryfall/client.ts` from the Web codebase. All
/// behavior — rate limit (200ms / 5 req/sec), 429 retry-after, JA two-step
/// lookup, dir=desc pagination, MAX_PAGES=30, isPaperPrinting filter —
/// mirrors the Web implementation 1:1 so the JSON backup bridge and search
/// experience stay consistent across platforms.
actor ScryfallClient {
    static let shared = ScryfallClient()

    private let baseURL = URL(string: "https://api.scryfall.com")!
    private let session: URLSession

    /// 200 ms minimum gap between requests. Scryfall caps at 10 req/sec; we
    /// keep a comfortable safety margin since a single basic-land search
    /// can burst 20+ paged requests in succession.
    private let rateLimitInterval: TimeInterval = 0.2

    private var lastRequestAt: Date = .distantPast

    /// Pagination cap. 30 pages × 175 prints = 5250 — comfortably covers
    /// Island and other heavily-reprinted cards.
    private let maxPages = 30

    /// Cap on the number of distinct oracle_ids carried from JA-search step 1
    /// into step 2. The OR clause in `oracleid:X or oracleid:Y` blows past
    /// Scryfall's URL length limit beyond ~10 entries.
    private let maxOracleIds = 10

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - Public API

    /// Top-level search entry. Mirrors `searchCards(query, fuzzy)` in the
    /// Web client. JA queries take the two-step path (oracle resolution
    /// then all-printings fetch). EN queries skip directly to the prints
    /// search with `lang:any`.
    func searchCards(_ query: String, fuzzy: Bool = false) async throws -> [NormalizedCard] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let isJa = containsJapanese(trimmed)
        // Strict mode wraps the query in Scryfall's exact-name operator.
        // Fuzzy mode passes the raw string for partial matching.
        let expr = fuzzy ? trimmed : "!\"\(trimmed.replacingOccurrences(of: "\"", with: ""))\""
        if isJa {
            return try await searchByJapaneseName(expr, fuzzy: fuzzy)
        }
        return try await searchAllPrintings(expr)
    }

    /// Fetches a specific printing by `{set, collector_number}`. Also probes
    /// the `{cn}★` variant — Scryfall stores foil-only Secret Lair / showcase
    /// reprints under that suffix.
    func fetchCardBySetAndNumber(set: String, collectorNumber cn: String) async throws -> [NormalizedCard] {
        let numbersToTry: [String] = cn.contains("★") ? [cn] : [cn, "\(cn)★"]

        var collected: [NormalizedCard] = []
        var anyHit = false

        for num in numbersToTry {
            let setEsc = urlEncode(set)
            let cnEsc = urlEncode(num)
            let url = baseURL.appendingPathComponent("cards/\(setEsc)/\(cnEsc)")
            let (data, response) = try await dispatch(url: url)
            if (response as? HTTPURLResponse)?.statusCode == 404 { continue }
            let card = try decode(ScryfallCard.self, from: data)
            guard isPaperPrinting(card) else { continue }
            anyHit = true
            let normalized = normalize(card)
            let nameJa = try? await fetchJapaneseName(set: set, collectorNumber: num)
            // Patch JA name across all finish variants for this printing.
            collected.append(contentsOf: normalized.map { card in
                NormalizedCard(
                    scryfallId: card.scryfallId,
                    nameEn: card.nameEn,
                    nameJa: card.nameJa ?? nameJa,
                    setCode: card.setCode,
                    collectorNumber: card.collectorNumber,
                    lang: card.lang,
                    finish: card.finish,
                    imageURL: card.imageURL,
                    oracleId: card.oracleId,
                    cachedAt: card.cachedAt,
                    legalities: card.legalities,
                    frame: card.frame,
                    borderColor: card.borderColor,
                    frameEffects: card.frameEffects,
                    fullArt: card.fullArt,
                    textless: card.textless,
                    setType: card.setType,
                    promoTypes: card.promoTypes
                )
            })
        }
        if !anyHit { return [] }
        return collected
    }

    /// Fetches the localized JA `printed_name` for a specific printing.
    /// Returns nil for prints without a Japanese release (Scryfall 404s).
    func fetchJapaneseName(set: String, collectorNumber cn: String) async throws -> String? {
        let url = baseURL.appendingPathComponent(
            "cards/\(urlEncode(set))/\(urlEncode(cn))/ja"
        )
        let (data, response) = try await dispatch(url: url)
        if (response as? HTTPURLResponse)?.statusCode == 404 { return nil }
        let card = try decode(ScryfallCard.self, from: data)
        return card.printedName
            ?? card.cardFaces?.first(where: { $0.printedName != nil })?.printedName
    }

    // MARK: - JA two-step

    private func searchByJapaneseName(_ jaQuery: String, fuzzy: Bool) async throws -> [NormalizedCard] {
        // Step 1: oracle_id discovery via lang:ja narrowing.
        let stepOneQuery = "lang:ja \(jaQuery)"
        let stepOneURL = baseURL.appendingPathComponent("cards/search")
            .appending(queryItems: [
                URLQueryItem(name: "q", value: stepOneQuery),
                URLQueryItem(name: "unique", value: "cards"),
                URLQueryItem(name: "page_size", value: "20"),
            ])
        let (data, response) = try await dispatch(url: stepOneURL)
        if (response as? HTTPURLResponse)?.statusCode == 404 {
            // Strict miss; fall back to fuzzy with the same query stripped
            // of the `!"..."` wrapping.
            if !fuzzy {
                let stripped = jaQuery
                    .replacingOccurrences(of: "!\"", with: "")
                    .replacingOccurrences(of: "\"", with: "")
                return try await searchByJapaneseName(stripped, fuzzy: true)
            }
            return []
        }
        let body = try decode(ScryfallSearchResponse.self, from: data)

        // Dedupe oracle_ids while preserving Scryfall's relevance order, then
        // cap at maxOracleIds (URL length safety).
        var seen = Set<String>()
        var oracleIds: [String] = []
        for card in body.data where !seen.contains(card.oracleId) {
            seen.insert(card.oracleId)
            oracleIds.append(card.oracleId)
            if oracleIds.count >= maxOracleIds { break }
        }
        guard !oracleIds.isEmpty else { return [] }

        // Step 2: fetch every printing across those oracles.
        let orClause = oracleIds.map { "oracleid:\($0)" }.joined(separator: " or ")
        return try await searchAllPrintings("(\(orClause))")
    }

    // MARK: - All printings (paginated)

    private func searchAllPrintings(_ scryfallQuery: String) async throws -> [NormalizedCard] {
        let langClause = scryfallQuery.contains("lang:") ? "" : " lang:any"
        var nextURL: URL? = baseURL
            .appendingPathComponent("cards/search")
            .appending(queryItems: [
                URLQueryItem(name: "q", value: scryfallQuery + langClause),
                URLQueryItem(name: "unique", value: "prints"),
                URLQueryItem(name: "include_variations", value: "true"),
                URLQueryItem(name: "order", value: "released"),
                URLQueryItem(name: "dir", value: "desc"),
            ])

        var all: [NormalizedCard] = []
        var page = 0
        while let url = nextURL, page < maxPages {
            let (data, response) = try await dispatch(url: url)
            if (response as? HTTPURLResponse)?.statusCode == 404 { return all }
            let body = try decode(ScryfallSearchResponse.self, from: data)
            let batch = body.data.filter(isPaperPrinting).flatMap(normalize)
            all.append(contentsOf: batch)
            nextURL = (body.hasMore == true) ? body.nextPage.flatMap(URL.init(string:)) : nil
            page += 1
        }
        return all
    }

    // MARK: - HTTP dispatch w/ rate limit + 429 retry

    private func dispatch(url: URL, retries: Int = 2) async throws -> (Data, URLResponse) {
        // Single-actor serialization keeps `lastRequestAt` honest under
        // concurrent calls; even from multiple Tasks we get a steady cadence.
        let now = Date()
        let elapsed = now.timeIntervalSince(lastRequestAt)
        if elapsed < rateLimitInterval {
            try? await Task.sleep(for: .seconds(rateLimitInterval - elapsed))
        }
        lastRequestAt = Date()

        var request = URLRequest(url: url)
        request.setValue("MtG-Wishlist/0.1 iOS", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)

        if let http = response as? HTTPURLResponse {
            if http.statusCode == 429, retries > 0 {
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After")
                    .flatMap { TimeInterval($0) } ?? 60
                try? await Task.sleep(for: .seconds(retryAfter))
                return try await dispatch(url: url, retries: retries - 1)
            }
            // 404 is a normal "no such card" — let the caller decide. Other
            // 4xx/5xx surface as ScryfallError so the UI can show details.
            if http.statusCode != 404 && (http.statusCode >= 400) {
                if let err = try? JSONDecoder().decode(ScryfallError.self, from: data) {
                    throw err
                }
                throw URLError(.badServerResponse)
            }
        }
        return (data, response)
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Helpers

/// Matches `containsJapanese` in the Web client: a single hiragana / katakana
/// / kanji codepoint flips the query into the JA-search branch.
private func containsJapanese(_ s: String) -> Bool {
    for scalar in s.unicodeScalars {
        switch scalar.value {
        case 0x3040...0x309F: return true  // Hiragana
        case 0x30A0...0x30FF: return true  // Katakana
        case 0x4E00...0x9FFF: return true  // CJK Unified Ideographs (kanji)
        default: continue
        }
    }
    return false
}

/// Filters out printings that don't exist as paper cards. MTGO/Arena-only
/// rows (`digital: true`), non-paper game targets, and gold-border 30th
/// Anniversary prints are all excluded so they don't pollute the search
/// results (matches the Web implementation).
private func isPaperPrinting(_ card: ScryfallCard) -> Bool {
    if card.digital == true { return false }
    if let games = card.games, !games.contains("paper") { return false }
    if card.borderColor == "gold" { return false }
    return true
}

private func urlEncode(_ s: String) -> String {
    s.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? s
}

private extension URL {
    func appending(queryItems: [URLQueryItem]) -> URL {
        var comps = URLComponents(url: self, resolvingAgainstBaseURL: false) ?? URLComponents()
        var existing = comps.queryItems ?? []
        existing.append(contentsOf: queryItems)
        comps.queryItems = existing
        return comps.url ?? self
    }
}
