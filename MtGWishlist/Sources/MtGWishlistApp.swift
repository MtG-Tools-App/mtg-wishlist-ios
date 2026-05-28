import SwiftUI

/// Entry point. The font inventory dump fires once at process start so the
/// Xcode console always shows the actual PostScript names that resolved
/// inside the simulator — that's how we close the "you guessed the wrong
/// name" gap without round-tripping back to the design spec.
@main
struct MtGWishlistApp: App {
    init() {
        FontInventory.dump()
        FontInventory.verify()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
