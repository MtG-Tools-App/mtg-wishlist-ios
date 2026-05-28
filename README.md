# MtG Wishlist — iOS

SwiftUI native iOS app for tracking a Magic: The Gathering wishlist.
Companion to the web version at
[mtg-wishlist](https://github.com/MtG-Tools-App/mtg-wishlist) — the web
build is the design reference, frozen; this repo is where the polished
mobile experience lives.

## Stack

- SwiftUI, iOS 26+ (Liquid Glass)
- iPhone only (no iPad), portrait only
- XcodeGen for terminal-driven project generation
- Bundle ID: `com.mtgtools.wishlist`

## Setup

```bash
brew install xcodegen
xcodegen generate          # produces MtGWishlist.xcodeproj
open MtGWishlist.xcodeproj # or build via xcodebuild
```

Build & run on simulator:

```bash
xcodebuild \
  -project MtGWishlist.xcodeproj \
  -scheme MtGWishlist \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

## Bundled fonts

All three font families are OFL-licensed and bundled in
`MtGWishlist/Resources/Fonts/`:

- **Noto Serif JP** (Regular / Medium / SemiBold) — Japanese UI, body,
  headings, card names
- **Oranienbaum** Regular — Latin display headings, candidate A
- **Vidaloka** Regular — Latin display headings, candidate B

The active Latin display family is selected from `AppFont.swift` so
A/B comparisons are a one-line change.

## Color tokens

11 color tokens in `Assets.xcassets`, light-mode only for now. See
`AppColor.swift` for the semantic Swift accessors. Hard-coded colors
are forbidden — always go through the token API.

## Resuming work in a fresh Claude Code session

Start with `docs/RESUME.md` — it's the 5-minute brief on current
progress, environment commands, launch flags, file layout, and the
decision log. `docs/PORT-PLAN.md` covers the underlying design and
phase rationale; refer there once `RESUME.md` is digested.

## Verifying fonts at runtime

The app dumps every registered family + PostScript name on first
launch (`FontInventory.swift`). Confirm in the Xcode console that all
three families are listed before assuming `Font.custom(...)` will hit
the right face.
