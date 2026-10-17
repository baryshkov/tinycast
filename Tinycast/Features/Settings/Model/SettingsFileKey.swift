import Foundation

/// Every key settings.json holds, in the order the file lists them; the raw value is its path.
enum SettingsFileKey: String, CaseIterable, Sendable {
    // Spelled out, so renaming a case can never rename a key in someone's file.
    case popToRootTimeout = "general.popToRootSeconds"
    case autoSwitchInputSource = "general.autoSwitchInputSource"
    case appearance = "appearance.theme"
    case interfaceSize = "appearance.interfaceSize"
    case compactMode = "appearance.compactMode"
    case showFavoritesInCompactMode = "appearance.showFavoritesInCompactMode"
    case openOnCursorScreen = "appearance.followCursorAcrossDisplays"
    case paletteDraggable = "appearance.dragToReposition"
    case launcherShowsSuggestions = "search.showsSuggestions"
    case rootSearchSensitivity = "search.sensitivity"
    case searchScopes = "applications.searchScopes"
    case customCommandsEnabled = "commands.enabled"
    case customCommandsShowInLauncher = "commands.showInLauncher"
    case quicklinksEnabled = "quicklinks.enabled"
    case quicklinksShowInLauncher = "quicklinks.showInLauncher"
    case quicklinkOpensNewWindow = "quicklinks.opensNewWindow"
    case quicklinkConfirmsBeforeDelete = "quicklinks.confirmsBeforeDelete"
    case fileSearchEnabled = "fileSearch.enabled"
    case fileSearchScopes = "fileSearch.scopes"
    case fileSearchIgnorePatterns = "fileSearch.ignorePatterns"
    case fileSearchShowInLauncher = "fileSearch.showInLauncher"
    case notesEnabled = "notes.enabled"
    case snippetsShowInLauncher = "snippets.showInLauncher"
    case navigationEnabled = "navigation.enabled"
    case windowManagementEnabled = "windowManagement.enabled"
    case windowCycle = "windowManagement.cycle"
    case windowLayoutsShowInLauncher = "windowManagement.layoutsShowInLauncher"
    case windowRoomsShowInLauncher = "windowManagement.roomsShowInLauncher"
    case clipboardRetention = "clipboard.retentionDays"
    case clipboardDisabledApps = "clipboard.disabledApps"
    case emojiSkinTone = "emoji.skinTone"
    case extensionsShowInLauncher = "extensions.showInLauncher"

    var section: String { String(rawValue.prefix { $0 != "." }) }

    var name: String { String(rawValue.drop { $0 != "." }.dropFirst()) }

    /// Every section, in file order.
    static let sections: [String] = allCases.reduce(into: []) { sections, key in
        if sections.last != key.section { sections.append(key.section) }
    }
}
