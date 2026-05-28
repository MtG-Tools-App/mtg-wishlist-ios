import SwiftUI

/// Design-token verification preview. Originally the root `ContentView`
/// from Phase 0; relocated to `DebugViews/` once the real WishlistView
/// took over as the app root in Phase 2.
///
/// Three sections cover the entire design-token surface:
///   1. Typography — Latin display × JP serif × mixed-language body
///   2. Colors — every Color Set rendered as a swatch
///   3. Material — Liquid Glass / SwiftUI Material on a cream backdrop
///
/// Use this as the eyeball spec test. When fonts and colors look right
/// here, the rest of the app inherits them through `AppFont` / `Color.*`.
/// Renders the typography × color × material design-token surface as a
/// scrollable single screen. Accessible from `WishlistView`'s toolbar (debug
/// menu); not shown to end users.
struct StyleGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                typographySection
                colorSection
                materialSection
            }
            .padding(24)
        }
        .background(Color.bgCanvas)
        .preferredColorScheme(.light)
    }

    // MARK: - Typography

    private var typographySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Typography")

            // Latin-only marquee. Watch this swap when you flip
            // `AppFont.latinDisplay` between .oranienbaum and .vidaloka.
            Text("WISHLIST")
                .font(.appDisplayLarge())
                .foregroundColor(.textPrimary)
                .padding(.bottom, 4)

            Text("ウィッシュリスト")
                .font(.appTitle())
                .foregroundColor(.textPrimary)

            // Mixed JA-EN — verify Noto Serif JP carries both scripts cleanly.
            Text("Lightning Bolt / 稲妻")
                .font(.appHeadline())
                .foregroundColor(.textPrimary)

            Text("欲しいカードと希望価格をまとめて管理する、明朝で組んだ静かなウィッシュリスト。 The wishlist is the treasure list.")
                .font(.appBody())
                .foregroundColor(.textPrimary)
                .lineSpacing(4)

            Text("(M21) #162 · NM · ¥300")
                .font(.appCaption())
                .foregroundColor(.textSecondary)
        }
    }

    // MARK: - Colors

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Colors")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                ],
                spacing: 12
            ) {
                colorSwatch("bgCanvas", .bgCanvas)
                colorSwatch("bgSurface", .bgSurface)
                colorSwatch("bgElevated", .bgElevated)
                colorSwatch("separator", .separator)
                colorSwatch("textPrimary", .textPrimary)
                colorSwatch("textSecondary", .textSecondary)
                colorSwatch("textTertiary", .textTertiary)
                colorSwatch("accentInk", .accentInk)
                colorSwatch("accentSignature", .accentSignature)
                colorSwatch("accentWash", .accentWash)
                colorSwatch("destructive", .destructive)
            }
        }
    }

    // MARK: - Material

    private var materialSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Material (Liquid Glass)")

            ZStack {
                // Colored backdrop so the glass blur has something to chew on.
                LinearGradient(
                    colors: [.accentSignature, .accentWash, .bgSurface],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 140)

                Text("Glass overlay sample")
                    .font(.appHeadline())
                    .foregroundColor(.textPrimary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        .regularMaterial,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.appHeadline())
            .foregroundColor(.textSecondary)
    }

    private func colorSwatch(_ name: String, _ color: Color) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 8)
                .fill(color)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.separator, lineWidth: 0.5)
                )
            Text(name)
                .font(.appCaption())
                .foregroundColor(.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    StyleGuideView()
}
