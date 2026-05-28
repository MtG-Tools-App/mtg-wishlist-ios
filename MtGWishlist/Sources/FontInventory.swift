import UIKit

/// Runtime introspection for the bundled fonts. SwiftUI's `Font.custom(_:size:)`
/// silently falls back to the system font when the PostScript name doesn't
/// match — there's no compile-time check and no runtime warning by default.
/// This helper makes the failure mode loud:
///
/// 1. `dump()` lists every registered family + PostScript name, so we can
///    eyeball the actual names of the three OFL families bundled here.
/// 2. `verify()` checks every name we depend on (`AppFont.*`) and prints
///    the missing ones, which makes any mismatch instantly fixable.
///
/// Both are called once from `MtGWishlistApp.init()`.
enum FontInventory {
    static func dump() {
        print("=== FontInventory.dump ===")
        for family in UIFont.familyNames.sorted() {
            // Filter to only show the bundled families plus a couple system
            // ones for context. Without the filter the console floods with
            // 80+ system families that aren't actionable.
            let interesting = family.lowercased().contains("noto")
                || family.lowercased().contains("oranienbaum")
                || family.lowercased().contains("vidaloka")
                || family == "Helvetica"
                || family == ".AppleSystemUIFont"
            guard interesting else { continue }
            print("  family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("    - \(name)")
            }
        }
        print("=== end ===")
    }

    static func verify() {
        let required: [String] = [
            AppFont.jaRegular,
            AppFont.jaMedium,
            AppFont.jaSemiBold,
            AppFont.LatinDisplay.oranienbaum.psName,
            AppFont.LatinDisplay.vidaloka.psName,
        ]
        let missing = required.filter { UIFont(name: $0, size: 12) == nil }
        if missing.isEmpty {
            print("[FontInventory] all required PostScript names resolved ✓")
        } else {
            print("[FontInventory] MISSING: \(missing)")
            print("[FontInventory] → check the dump above for the actual names and update AppFont.swift")
        }
    }
}
