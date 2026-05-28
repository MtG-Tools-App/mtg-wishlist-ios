import SwiftUI

/// A horizontally-scrolling row of pill-shaped chips. One chip is "selected"
/// at any time; tapping a different chip calls the binding setter.
///
/// Shared between the AddCardView lang / finish / frame filter rows; the
/// `FormatFilterTabs` in the wishlist uses a slightly different visual
/// treatment so it's not reused here, but the chip shape is the same.
struct FilterChipRow<Option: Hashable & Identifiable>: View {
    let title: String
    @Binding var selection: Option
    let options: [Option]
    let label: (Option) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.textTertiary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(options) { option in
                        chip(
                            label: label(option),
                            isSelected: option == selection
                        ) {
                            selection = option
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func chip(
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.appCaption().weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.bgCanvas : Color.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule().fill(isSelected ? Color.accentInk : Color.bgSurface)
                )
                .overlay(
                    Capsule().strokeBorder(
                        isSelected ? Color.clear : Color.separator,
                        lineWidth: 0.5
                    )
                )
        }
        .buttonStyle(.plain)
    }
}
