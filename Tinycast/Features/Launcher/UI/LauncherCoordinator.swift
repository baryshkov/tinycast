import AppKit

/// Owns launcher activation: the one funnel from a palette row to whatever the entry's kind runs.
@MainActor
final class LauncherCoordinator {
    private let ranking: LauncherRankingStore
    private let windowController: PaletteWindowController
    private let paletteCoordinator: PaletteCoordinator
    private let settingsCoordinator: SettingsCoordinator
    private let customCommandCoordinator: CustomCommandCoordinator
    private let systemActionCoordinator: SystemActionCoordinator
    private let quicklinkCoordinator: QuicklinkCoordinator
    private let windowCommandCoordinator: WindowCommandCoordinator
    private let snippetExpansion: SnippetExpansionCoordinator
    private let fileSearchCoordinator: FileSearchCoordinator
    private let notesCoordinator: NotesCoordinator
    private let extensionCoordinator: ExtensionCoordinator
    /// The backup commands only, which need the live stores to gather from and apply to.
    private unowned let core: AppCore

    init(
        ranking: LauncherRankingStore,
        windowController: PaletteWindowController,
        paletteCoordinator: PaletteCoordinator,
        settingsCoordinator: SettingsCoordinator,
        customCommandCoordinator: CustomCommandCoordinator,
        systemActionCoordinator: SystemActionCoordinator,
        quicklinkCoordinator: QuicklinkCoordinator,
        windowCommandCoordinator: WindowCommandCoordinator,
        snippetExpansion: SnippetExpansionCoordinator,
        fileSearchCoordinator: FileSearchCoordinator,
        notesCoordinator: NotesCoordinator,
        extensionCoordinator: ExtensionCoordinator,
        core: AppCore
    ) {
        self.ranking = ranking
        self.windowController = windowController
        self.paletteCoordinator = paletteCoordinator
        self.settingsCoordinator = settingsCoordinator
        self.customCommandCoordinator = customCommandCoordinator
        self.systemActionCoordinator = systemActionCoordinator
        self.quicklinkCoordinator = quicklinkCoordinator
        self.windowCommandCoordinator = windowCommandCoordinator
        self.snippetExpansion = snippetExpansion
        self.fileSearchCoordinator = fileSearchCoordinator
        self.notesCoordinator = notesCoordinator
        self.extensionCoordinator = extensionCoordinator
        self.core = core
    }

    // MARK: - Activation

    func launch(
        _ app: AppEntry, searchQuery: String? = nil, arguments: [String: String] = [:]
    ) {
        // A category listing is not a search for the row that ran; learning it would rank it under "s".
        if let searchQuery, AppEntry.Kind.named(by: searchQuery) == nil {
            ranking.visit(itemKey: app.preferenceKey, query: searchQuery)
        }
        // Commands dispatch before the palette hides: mode-switching commands keep it open.
        if app.kind == .command {
            runCommand(app, searchQuery: searchQuery)
            return
        }
        if app.kind == .customCommand {
            guard let id = CustomCommand.id(fromEntryID: app.id) else { return }
            customCommandCoordinator.runCustomCommand(id: id)
            return
        }
        if app.kind == .systemAction {
            guard let action = SystemActionCatalog.action(forEntryID: app.id) else { return }
            systemActionCoordinator.runSystemAction(id: action.id)
            return
        }
        if let id = CustomWindowSize.id(fromEntryID: app.id) { windowCommandCoordinator.runCustomWindowSize(id: id); return }
        if let id = WindowLayout.id(fromEntryID: app.id) { core.windowLayoutCoordinator.runWindowLayout(id: id); return }
        if let id = Room.id(fromEntryID: app.id) { core.roomCoordinator.enterRoom(id: id); return }
        if app.kind == .windowCommand {
            guard let command = WindowCommandCatalog.command(forEntryID: app.id) else { return }
            windowCommandCoordinator.runWindowCommand(id: command.id)
            return
        }
        // Before the palette hides: a view command takes the palette over rather than closing it.
        if app.kind == .extensionCommand {
            extensionCoordinator.runExtensionCommand(app, arguments: arguments)
            return
        }
        // Before the palette hides: an unfilled quicklink stays up to ask first.
        if app.kind == .quicklink {
            guard let id = Quicklink.id(fromEntryID: app.id) else { return }
            quicklinkCoordinator.openQuicklink(id: id)
            return
        }
        let previous = windowController.previousApp
        paletteCoordinator.hidePalette(restoreFocus: false)
        switch app.kind {
        case .application:
            AppLauncher.launch(app.url, allowsRunningApplicationSubstitution: app.isPrimaryInstallation)
        case .systemSettings:
            guard let bundleID = app.bundleID else { return }
            AppLauncher.openSettingsPane(bundleID: bundleID)
        case .snippet:
            let snippetID = String(app.id.dropFirst("snippet:".count))
            snippetExpansion.expandSnippet(id: snippetID, targetApp: previous)
        case .command, .customCommand, .systemAction, .windowCommand, .quicklink,
            .extensionCommand:
            break  // handled above
        }
    }

    private func runCommand(_ entry: AppEntry, searchQuery: String?) {
        switch CommandCatalog.command(for: entry) {
        case .startClockTimer:
            startClockTimer(query: searchQuery ?? "")
        case .switchWindowsBackwards: core.windowSwitchCoordinator.show(backwards: true)
        case .switchWindows: core.windowSwitchCoordinator.show()
        case .switchRoom: core.roomCoordinator.showRooms()
        case .createRoom: core.roomCoordinator.createRoom()
        case .createWindowLayout: core.windowLayoutCoordinator.editWindowLayout(nil)
        case .captureWindowLayout: core.windowLayoutCoordinator.captureWindowLayout()
        case .openCamera:
            paletteCoordinator.hidePalette(restoreFocus: false)
            Task { await core.cameraCoordinator.show() }
        case .calculatorHistory:
            paletteCoordinator.showPalette(mode: .calculatorHistory)
        case .clipboardHistory:
            paletteCoordinator.showPalette(mode: .clipboard)
        case .searchEmoji:
            paletteCoordinator.showPalette(mode: .emoji)
        case .searchFiles:
            fileSearchCoordinator.show()
        case .showNotes:
            paletteCoordinator.hidePalette(restoreFocus: false)
            notesCoordinator.show()
        case .createNote:
            paletteCoordinator.hidePalette(restoreFocus: false)
            notesCoordinator.createNote()
        case .searchNotes:
            paletteCoordinator.hidePalette(restoreFocus: false)
            notesCoordinator.searchNotes()
        case .searchQuicklinks:
            paletteCoordinator.showPalette(mode: .quicklinks)
        case .createQuicklink:
            paletteCoordinator.hidePalette(restoreFocus: false)
            quicklinkCoordinator.editQuicklink(nil)
        case .importQuicklinks:
            paletteCoordinator.hidePalette(restoreFocus: false)
            Task { await quicklinkCoordinator.importQuicklinks() }
        case .exportQuicklinks:
            paletteCoordinator.hidePalette(restoreFocus: false)
            Task { await quicklinkCoordinator.exportQuicklinks() }
        case .exportSettings:
            paletteCoordinator.hidePalette(restoreFocus: false)
            Task { await BackupActions.runExportCommand(core: core) }
        case .importSettings:
            paletteCoordinator.hidePalette(restoreFocus: false)
            Task { await BackupActions.runImportCommand(core: core) }
        case .importFromRaycast:
            paletteCoordinator.hidePalette(restoreFocus: false)
            settingsCoordinator.showBackupSettings()
        case .settings:
            paletteCoordinator.hidePalette(restoreFocus: false)
            settingsCoordinator.showSettings()
        case .about:
            paletteCoordinator.hidePalette(restoreFocus: false)
            settingsCoordinator.showAbout()
        case .quit:
            NSApp.terminate(nil)
        case nil:
            break
        }
    }

    // MARK: - Row actions

    private func startClockTimer(query: String) {
        guard let request = ClockTimerRequest(query: query) else {
            core.palette.query = "timer "
            return
        }
        paletteCoordinator.hidePalette(restoreFocus: false)
        Task {
            if let error = await ClockTimerRunner.run(request) {
                await core.showNotice(
                    title: "Couldn’t Start Clock Timer",
                    message: error + "\n\nThe Shortcut ‘Tinycast Timer’ must run Clock’s Start Timer action"
                        + " using Shortcut Input as seconds.",
                    symbol: "timer", tone: .danger)
            }
        }
    }

    func resetRanking(for app: AppEntry) {
        ranking.reset(itemKey: app.preferenceKey)
    }

    func showInFinder(_ app: AppEntry) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        AppLauncher.showInFinder(app.url)
    }

    /// Quits the app behind an entry; a no-op (palette stays put) when it isn't running.
    func restart(_ app: AppEntry) {
        guard app.kind == .application, let bundleID = app.bundleID else { return }
        paletteCoordinator.hidePalette(restoreFocus: false)
        Task { await AppLauncher.restart(bundleID: bundleID, url: app.url) }
    }

    func quit(_ app: AppEntry, force: Bool = false) {
        guard app.kind == .application, let bundleID = app.bundleID else { return }
        // Nothing here takes focus, so hand it back unless that app is on its way out.
        let quittingPreviousApp = windowController.previousApp?.bundleIdentifier == bundleID
        guard AppLauncher.quit(bundleID: bundleID, url: app.url, force: force) else { return }
        paletteCoordinator.hidePalette(restoreFocus: !quittingPreviousApp)
    }
}
