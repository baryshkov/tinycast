import Foundation

@MainActor
enum SettingsFileSchema {
    static func bindings(settings: AppSettings) -> [SettingsFileBinding] {
        SettingsFileKey.allCases.map { key in
            switch key {
            case .popToRootTimeout: return SettingsFileBinding(key, settings, \.popToRootTimeout)
            case .autoSwitchInputSource: return SettingsFileBinding(key, settings, \.autoSwitchInputSourceID)
            case .appearance: return SettingsFileBinding(key, settings, \.appearance)
            case .interfaceSize: return SettingsFileBinding(key, settings, \.interfaceSize)
            case .compactMode: return SettingsFileBinding(key, settings, \.compactMode)
            case .showFavoritesInCompactMode:
                return SettingsFileBinding(key, settings, \.showFavoritesInCompactMode)
            case .openOnCursorScreen: return SettingsFileBinding(key, settings, \.openOnCursorScreen)
            case .paletteDraggable: return SettingsFileBinding(key, settings, \.paletteDraggable)
            case .launcherShowsSuggestions:
                return SettingsFileBinding(key, settings, \.launcherShowsSuggestions)
            case .rootSearchSensitivity: return SettingsFileBinding(key, settings, \.rootSearchSensitivity)
            case .searchScopes: return SettingsFileBinding(key, settings, \.searchScopes)
            case .customCommandsEnabled: return SettingsFileBinding(key, settings, \.customCommandsEnabled)
            case .customCommandsShowInLauncher:
                return SettingsFileBinding(key, settings, \.customCommandsShowInLauncher)
            case .quicklinksEnabled: return SettingsFileBinding(key, settings, \.quicklinksEnabled)
            case .quicklinksShowInLauncher:
                return SettingsFileBinding(key, settings, \.quicklinksShowInLauncher)
            case .quicklinkOpensNewWindow:
                return SettingsFileBinding(key, settings, \.quicklinkOpensNewWindow)
            case .quicklinkConfirmsBeforeDelete:
                return SettingsFileBinding(key, settings, \.quicklinkConfirmsBeforeDelete)
            case .fileSearchEnabled: return SettingsFileBinding(key, settings, \.fileSearchEnabled)
            case .fileSearchScopes: return SettingsFileBinding(key, settings, \.fileSearchScopes)
            case .fileSearchIgnorePatterns:
                return SettingsFileBinding(key, settings, \.fileSearchIgnorePatterns)
            case .fileSearchShowInLauncher:
                return SettingsFileBinding(key, settings, \.fileSearchShowInLauncher)
            case .notesEnabled: return SettingsFileBinding(key, settings, \.notesEnabled)
            case .snippetsShowInLauncher: return SettingsFileBinding(key, settings, \.snippetsShowInLauncher)
            case .navigationEnabled: return SettingsFileBinding(key, settings, \.navigationEnabled)
            case .windowManagementEnabled:
                return SettingsFileBinding(key, settings, \.windowManagementEnabled)
            case .windowCycle: return SettingsFileBinding(key, settings, \.windowCycle)
            case .windowLayoutsShowInLauncher:
                return SettingsFileBinding(key, settings, \.windowLayoutsShowInLauncher)
            case .windowRoomsShowInLauncher:
                return SettingsFileBinding(key, settings, \.windowRoomsShowInLauncher)
            case .clipboardRetention: return SettingsFileBinding(key, settings, \.clipboardRetention)
            case .clipboardDisabledApps: return SettingsFileBinding(key, settings, \.clipboardDisabledApps)
            case .emojiSkinTone: return SettingsFileBinding(key, settings, \.emojiSkinTone)
            case .extensionsShowInLauncher:
                return SettingsFileBinding(key, settings, \.extensionsShowInLauncher)
            }
        }
    }
}

extension AppAppearance: SettingsFileRawValue {}
extension ClipboardRetention: SettingsFileRawValue {}
extension EmojiSkinTone: SettingsFileRawValue {}
extension InterfaceSize: SettingsFileRawValue {}
extension PopToRootTimeout: SettingsFileRawValue {}
extension SearchSensitivity: SettingsFileRawValue {}
extension WindowCycle: SettingsFileRawValue {}
