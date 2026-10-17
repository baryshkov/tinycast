import Foundation

/// Built-in launcher actions, surfaced alongside the user-authored ones.
enum CommandID: String, CaseIterable, Sendable {
    case switchWindowsBackwards = "command:switch-windows-backwards"
    case switchWindows = "command:switch-windows"
    case switchRoom = "command:switch-room"
    case createRoom = "command:create-room"
    case createWindowLayout = "command:create-window-layout"
    case captureWindowLayout = "command:capture-window-layout"
    case openCamera = "command:open-camera"
    case calculatorHistory = "command:calculator-history"
    case clipboardHistory = "command:clipboard-history"
    case searchEmoji = "command:search-emoji"
    case searchFiles = "command:search-files"
    case showNotes = "command:show-notes"
    case createNote = "command:create-note"
    case searchNotes = "command:search-notes"
    case createQuicklink = "command:create-quicklink"
    case searchQuicklinks = "command:search-quicklinks"
    case importQuicklinks = "command:import-quicklinks"
    case exportQuicklinks = "command:export-quicklinks"
    case exportSettings = "command:export-settings"
    case importSettings = "command:import-settings"
    case importFromRaycast = "command:import-from-raycast"
    case settings = "command:settings"
    case about = "command:about"
    case quit = "command:quit"

    var name: String {
        switch self {
        case .switchWindowsBackwards: return "Switch Windows Backwards"
        case .switchWindows: return "Switch Windows"
        case .switchRoom: return "Switch Room"
        case .createRoom: return "Create Room"
        case .createWindowLayout: return "Create Window Layout"
        case .captureWindowLayout: return "Capture Window Layout"
        case .openCamera: return "Open Camera"
        case .calculatorHistory: return "Calculator History"
        case .clipboardHistory: return "Clipboard History"
        case .searchEmoji: return "Search Emoji & Symbols"
        case .searchFiles: return "Search Files"
        case .showNotes: return "Show Notes"
        case .createNote: return "Create Note"
        case .searchNotes: return "Search Notes"
        case .createQuicklink: return "Create Quicklink"
        case .searchQuicklinks: return "Search Quicklinks"
        case .importQuicklinks: return "Import Quicklinks"
        case .exportQuicklinks: return "Export Quicklinks"
        case .exportSettings: return "Export Tinycast Backup"
        case .importSettings: return "Import Tinycast Backup"
        case .importFromRaycast: return "Import from Raycast"
        case .settings: return "Settings"
        case .about: return "About Tinycast"
        case .quit: return "Quit Tinycast"
        }
    }

    var sfSymbol: String {
        switch self {
        case .switchWindowsBackwards: return "macwindow.on.rectangle"
        case .switchWindows: return "macwindow.on.rectangle"
        case .switchRoom: return "rectangle.3.group"
        case .createRoom: return "plus.rectangle.on.rectangle"
        case .createWindowLayout: return "rectangle.3.group"
        case .captureWindowLayout: return "rectangle.dashed.badge.record"
        case .openCamera: return "camera"
        case .calculatorHistory: return "plus.forwardslash.minus"
        case .clipboardHistory: return "doc.on.clipboard"
        case .searchEmoji: return "face.smiling"
        case .searchFiles: return "doc.text.magnifyingglass"
        case .showNotes: return "text.page"
        case .createNote: return "note.text.badge.plus"
        case .searchNotes: return "text.magnifyingglass"
        case .createQuicklink: return "link.badge.plus"
        case .searchQuicklinks: return Quicklink.sfSymbol
        case .importQuicklinks: return "square.and.arrow.down"
        case .exportQuicklinks: return "square.and.arrow.up"
        case .exportSettings: return "square.and.arrow.up"
        case .importSettings: return "square.and.arrow.down"
        case .importFromRaycast: return "arrow.down.doc"
        case .settings: return "gearshape"
        case .about: return "info.circle"
        case .quit: return "power"
        }
    }

    /// The built-ins with a global shortcut of their own; the rest open from the launcher.
    var hotKeyAction: HotKeyAction? {
        switch self {
        case .switchWindows: return .switchWindows
        case .switchWindowsBackwards: return .switchWindowsBackwards
        case .switchRoom: return .switchRoom
        case .createRoom: return .createRoom
        case .searchFiles: return .searchFiles
        case .clipboardHistory: return .toggleClipboard
        case .searchEmoji: return .toggleEmoji
        case .showNotes: return .showNotes
        case .createNote: return .createNote
        case .searchNotes: return .searchNotes
        default: return nil
        }
    }
}
