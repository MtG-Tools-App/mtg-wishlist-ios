import SwiftUI

/// Single source of truth for typography. Three rules:
///
///   1. Japanese / mixed JA-EN body → `Noto Serif JP`. Without a JP-aware
///      base font, Latin-only display faces (Oranienbaum / Vidaloka) fall
///      back to system Hiragino for any JP characters, which clashes
///      visually with the明朝 design language.
///   2. Latin-only decorative headings → Oranienbaum *or* Vidaloka. The
///      active choice is one constant (`latinDisplay`) so on-device A/B
///      comparison is a one-line code change. Strings hitting this style
///      must not contain Japanese — they will fall back to Hiragino.
///   3. Every size goes through `Font.custom(_, size:, relativeTo:)` so
///      Dynamic Type scales them. Hard-coded `Font(name:size:)` is
///      forbidden.
enum AppFont {
    /// Active Latin display face. Flip this to A/B Oranienbaum vs Vidaloka.
    static let latinDisplay: LatinDisplay = .vidaloka

    enum LatinDisplay: String, CaseIterable {
        case oranienbaum = "Oranienbaum-Regular"
        case vidaloka = "Vidaloka-Regular"
        /// PostScript name used by `Font.custom` / `UIFont(name:size:)`.
        /// Standard Google Fonts naming; `FontInventory.verify()` checks
        /// this at launch.
        var psName: String { rawValue }
    }

    // Noto Serif JP — Google Fonts standard PostScript names for the static
    // weight slices. Validated at launch by `FontInventory.verify()`.
    static let jaRegular = "NotoSerifJP-Regular"
    static let jaMedium = "NotoSerifJP-Medium"
    static let jaSemiBold = "NotoSerifJP-SemiBold"
}

extension Font {
    /// 40pt Latin-only display. Use for the app's marquee word ("WISHLIST",
    /// card name in English, etc.). Do NOT pass Japanese strings here —
    /// they will fall back to system Hiragino and break the明朝 voice.
    static func appDisplayLarge() -> Font {
        .custom(AppFont.latinDisplay.psName, size: 40, relativeTo: .largeTitle)
    }

    /// 24pt SemiBold Noto Serif JP. Section titles, screen titles. Safe for
    /// any language (Latin glyphs in Noto Serif JP are well-designed too).
    static func appTitle() -> Font {
        .custom(AppFont.jaSemiBold, size: 24, relativeTo: .title)
    }

    /// 18pt Medium. Card name, list item heading.
    static func appHeadline() -> Font {
        .custom(AppFont.jaMedium, size: 18, relativeTo: .headline)
    }

    /// 17pt Regular. Body text — descriptions, notes.
    static func appBody() -> Font {
        .custom(AppFont.jaRegular, size: 17, relativeTo: .body)
    }

    /// 12pt Regular. Meta info: collector number, set code, target price.
    /// Small-size明朝 can blur on low-DPR devices; if it bothers you in
    /// practice this is the one style to consider switching to Noto Sans JP.
    static func appCaption() -> Font {
        .custom(AppFont.jaRegular, size: 12, relativeTo: .caption)
    }
}
