import Foundation

/// Everything in Tinycast a global shortcut can be bound to.
enum HotKeyAction: Hashable, Sendable {
    case switchWindows, switchWindowsBackwards, switchRoom, createRoom
    case togglePalette
    case toggleClipboard
    case toggleEmoji
    case showNotes
    case createNote
    case searchNotes
    case searchFiles
    case app(bundleID: String)
    case settingsPane(bundleID: String)
    case customCommand(id: UUID)
    case systemAction(id: SystemAction.ID)
    case windowCommand(id: WindowCommand.ID)
    case customWindowSize(id: UUID)
    case windowLayout(id: UUID)
    case windowRoom(id: UUID)
    case quicklink(id: UUID)
    /// Keyed by `AppEntry.id` (`extension:<extension>/<command>`), which is what survives a
    /// reinstall — an extension carries no id of its own beyond its name.
    case extensionCommand(entryID: String)

    /// The UserDefaults key, and the `HotKeyCenter` registration id: one per action.
    var defaultsKey: String {
        switch self {
        case .switchWindows: "hotkey.switchWindows"
        case .switchWindowsBackwards: "hotkey.switchWindowsBackwards"
        case .switchRoom: "hotkey.switchRoom"
        case .createRoom: "hotkey.createRoom"
        case .togglePalette: "hotkey.togglePalette"
        case .toggleClipboard: "hotkey.toggleClipboard"
        case .toggleEmoji: "hotkey.toggleEmoji"
        case .showNotes: "hotkey.showNotes"
        case .createNote: "hotkey.createNote"
        case .searchNotes: "hotkey.searchNotes"
        case .searchFiles: "hotkey.searchFiles"
        case .app(let bundleID): "hotkey.app." + bundleID
        case .settingsPane(let bundleID): "hotkey.pane." + bundleID
        case .customCommand(let id): "hotkey.customCommand." + id.uuidString.lowercased()
        case .systemAction(let id): "hotkey.systemAction." + id.rawValue
        case .windowCommand(let id): "hotkey.windowCommand." + id.rawValue
        case .customWindowSize(let id): "hotkey.customWindowSize." + id.uuidString.lowercased()
        case .windowLayout(let id): "hotkey.windowLayout." + id.uuidString.lowercased()
        case .windowRoom(let id): "hotkey.windowRoom." + id.uuidString.lowercased()
        case .quicklink(let id): "hotkey.quicklink." + id.uuidString.lowercased()
        case .extensionCommand(let entryID): "hotkey.extensionCommand." + entryID
        }
    }

    /// The fixed actions every install can bind; the per-item catalogs extend them at launch.
    static let builtInActions: [HotKeyAction] = [
        .switchWindows, .switchWindowsBackwards, .switchRoom, .createRoom,
        .togglePalette, .toggleClipboard, .toggleEmoji, .showNotes, .createNote, .searchNotes,
        .searchFiles
    ]
}
