import Foundation

/// Canonical ordered list of format tags. Mirrors `src/lib/format/formats.ts`
/// in the Web codebase (`FORMAT_TAGS` constant). Adding a format here
/// propagates to the grouping order, filter tabs, and JSON backup parsing
/// — single source of truth.
enum FormatTag: String, CaseIterable, Identifiable, Codable {
    case standard
    case pioneer
    case modern
    case legacy
    case vintage
    case pauper
    case premodern
    case other

    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard:  return "Standard"
        case .pioneer:   return "Pioneer"
        case .modern:    return "Modern"
        case .legacy:    return "Legacy"
        case .vintage:   return "Vintage"
        case .pauper:    return "Pauper"
        case .premodern: return "Premodern"
        case .other:     return "Other"
        }
    }
}

/// Resolves a stored `format_tag` string (which can be nil = "Other" bucket)
/// into a display label. Matches the Web `formatLabel(tag)` helper.
func formatLabel(_ tag: String?) -> String {
    guard let tag, let fmt = FormatTag(rawValue: tag) else { return "Other" }
    return fmt.label
}

/// Top-bar filter selection. `nil` = show every format ("All" tab).
typealias FormatFilter = FormatTag?
