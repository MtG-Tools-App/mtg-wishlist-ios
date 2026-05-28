import SwiftData
import SwiftUI

/// Entry point. The font inventory dump fires once at process start so the
/// Xcode console always shows the actual PostScript names that resolved
/// inside the simulator — that's how we close the "you guessed the wrong
/// name" gap without round-tripping back to the design spec.
///
/// SwiftData stack: a single shared `ModelContainer` covering Card,
/// WishlistItem, and PriceLog. SwiftData picks the default on-device URL
/// (`Application Support/<bundle>/default.store`); no explicit schema
/// versioning yet — the app is pre-release, breaking changes can wipe.
@main
struct MtGWishlistApp: App {
    init() {
        FontInventory.dump()
        FontInventory.verify()
    }

    var body: some Scene {
        WindowGroup {
            WishlistView()
        }
        .modelContainer(for: [
            Card.self,
            WishlistItem.self,
            PriceLog.self,
        ])
    }
}
