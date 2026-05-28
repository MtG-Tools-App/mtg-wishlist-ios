import SwiftUI

/// Type-safe accessors for the 11 design tokens defined in Assets.xcassets.
/// Hard-coded colors are forbidden — always go through these properties.
///
/// Naming mirrors the design spec (`bg/canvas` → `bgCanvas`, etc.) so a
/// design diff can be cross-referenced one-to-one.
extension Color {
    // Backgrounds
    static let bgCanvas = Color("bgCanvas")
    static let bgSurface = Color("bgSurface")
    static let bgElevated = Color("bgElevated")

    // Structure
    static let separator = Color("separator")

    // Text
    static let textPrimary = Color("textPrimary")
    static let textSecondary = Color("textSecondary")
    static let textTertiary = Color("textTertiary")

    // Accents
    static let accentInk = Color("accentInk")
    /// Signature champagne / soft bronze. Reserved for wishlist treasure
    /// signals (★ favorite, ownership, etc.) — never for body text.
    static let accentSignature = Color("accentSignature")
    /// Pale champagne wash. Selected row backgrounds, soft tags.
    static let accentWash = Color("accentWash")

    /// Destructive actions only (delete confirmation, error). Used sparingly.
    static let destructive = Color("destructive")
}
