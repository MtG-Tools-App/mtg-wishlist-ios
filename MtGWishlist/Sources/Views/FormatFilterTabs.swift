import SwiftUI

/// Horizontal scroll of pill-shaped chips, one per format plus an "All" tab.
/// Selected chip uses the ink accent; unselected sit on the cream backdrop
/// with a thin separator outline.
///
/// Visually closer to the Web's V3 filter bar than a `Picker(.segmented)`
/// would be (a segmented control on iOS can't fit 9 buckets comfortably,
/// and forcing portrait layout makes overflow inevitable).
struct FormatFilterTabs: View {
    @Binding var selection: FormatFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(label: "All", isSelected: selection == nil) {
                    selection = nil
                }
                ForEach(FormatTag.allCases) { tag in
                    chip(label: tag.label, isSelected: selection == tag) {
                        selection = tag
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func chip(
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.appCaption().weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.bgCanvas : Color.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
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
