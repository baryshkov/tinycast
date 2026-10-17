import SwiftUI

struct WindowSwitchList: View {

    let entries: [WindowSwitchEntry]
    let selectedID: WindowSwitchEntry.ID?
    let scroll: ScrollIntent
    let onActivate: (WindowSwitchEntry) -> Void

    private var firstRowSelected: Bool {
        selectedID != nil && selectedID == entries.first?.id
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        WindowSwitchRow(entry: entry, selected: entry.id == selectedID)
                            .selectionFrame(entry.id == selectedID)
                            .contentShape(Rectangle())
                            .onTapGesture { onActivate(entry) }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .hideNativeScrollers()
                .scrollOriginAnchor()
            }
            .edgeDissolve()
            .thinScrollbar()
            .scrollFollowsSelection(
                scroll, row: selectedID, atOrigin: firstRowSelected, proxy: proxy)
        }
    }
}

private struct WindowSwitchRow: View {

    let entry: WindowSwitchEntry
    let selected: Bool
    @State private var hovered = false

    private var fill: Color {
        if selected { return Theme.Colors.selection }
        if hovered { return Theme.Colors.rowHover }
        return .clear
    }

    private var trailing: String {
        entry.isMinimized ? "\(entry.appName) · Minimized" : entry.appName
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Group {
                if let iconURL = entry.iconURL {
                    EntryIconView(source: .file, fileURL: iconURL)
                } else {
                    EntryIconView(source: .symbol("macwindow"))
                }
            }
            .frame(width: Theme.Size.resultRowIcon, height: Theme.Size.resultRowIcon)
            .opacity(entry.isMinimized ? 0.5 : 1)
            Text(entry.displayTitle)
                .font(Theme.Typography.rowTitle)
                .foregroundStyle(entry.isMinimized ? AnyShapeStyle(.secondary) : AnyShapeStyle(.primary))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: Theme.Spacing.md)
            Text(trailing)
                .font(Theme.Typography.rowTrailing)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                .fill(fill)
        )
        .armedHover($hovered)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.displayTitle)
        .accessibilityValue(trailing)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
