import SwiftUI

struct RoomPickerList: View {
    let rows: [RoomPickerRow]
    /// Room order; a member's place is its index plus one.
    let picked: [RoomSession.Pick]
    let selectedID: String?
    let scroll: ScrollIntent
    let onActivate: (RoomPickerRow) -> Void

    private var firstRowSelected: Bool { selectedID != nil && selectedID == rows.first?.id }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        RoomPickerRowView(
                            row: row, place: picked.firstIndex(of: row.pick).map { $0 + 1 },
                            selected: row.id == selectedID
                        )
                        .selectionFrame(row.id == selectedID)
                        .contentShape(Rectangle())
                        .onTapGesture { onActivate(row) }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.md)
                .hideNativeScrollers()
                .scrollOriginAnchor()
            }
            .edgeDissolve()
            .thinScrollbar()
            .scrollFollowsSelection(scroll, row: selectedID, atOrigin: firstRowSelected, proxy: proxy)
        }
    }
}

private struct RoomPickerRowView: View {
    let row: RoomPickerRow
    /// Its place in the room, 1 being the main window; nil when it is not in the room.
    let place: Int?
    let selected: Bool
    @State private var hovered = false

    private var fill: Color {
        if selected { return Theme.Colors.selection }
        if hovered { return Theme.Colors.rowHover }
        return .clear
    }

    private var title: String {
        switch row {
        case .window(let window):
            window.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? window.appName : window.title
        case .app(let app):
            app.name
        }
    }

    private var trailing: String {
        switch row {
        case .window(let window):
            if window.isAppHidden { return "\(window.appName) · Hidden" }
            if window.isMinimized { return "\(window.appName) · Minimized" }
            return window.appName
        case .app:
            return "App · Opens with the room"
        }
    }

    private var appURL: URL? {
        switch row {
        case .window(let window): window.appURL
        case .app(let app): app.url
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            badge
            Group {
                if let appURL {
                    EntryIconView(source: .file, fileURL: appURL)
                } else {
                    EntryIconView(source: .symbol("macwindow"))
                }
            }
            .frame(width: Theme.Size.resultRowIcon, height: Theme.Size.resultRowIcon)
            Text(title)
                .font(Theme.Typography.rowTitle)
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
            RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous).fill(fill)
        )
        .armedHover($hovered)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(place.map { "\(trailing), number \($0) in the room" } ?? trailing)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var badge: some View {
        ZStack {
            Circle()
                .strokeBorder(place == nil ? Theme.Colors.cardStroke : .clear, lineWidth: 1)
                .background(Circle().fill(place == nil ? .clear : Theme.Colors.roomCardStroke))
            if let place {
                Text("\(place)")
                    .font(Theme.Typography.rowTrailing.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: Theme.Size.resultRowIcon, height: Theme.Size.resultRowIcon)
    }
}
