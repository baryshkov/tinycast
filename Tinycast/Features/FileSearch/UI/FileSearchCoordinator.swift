import AppKit

@MainActor
final class FileSearchCoordinator {
    private let settings: AppSettings
    private let appIndex: AppIndex
    private let session: FileSearchSession
    private let indexer: FileIndexer
    private let palette: PaletteState
    private let paletteCoordinator: PaletteCoordinator
    private unowned let core: AppCore

    init(
        settings: AppSettings, appIndex: AppIndex, session: FileSearchSession, indexer: FileIndexer,
        palette: PaletteState, paletteCoordinator: PaletteCoordinator, core: AppCore
    ) {
        self.settings = settings
        self.appIndex = appIndex
        self.session = session
        self.indexer = indexer
        indexer.onIndexChanged = { [weak session] in session?.refresh() }
        indexer.onRecentChanged = { [weak session] in session?.refreshRecent() }
        self.palette = palette
        self.paletteCoordinator = paletteCoordinator
        self.core = core
    }

    func applyEnabled() {
        appIndex.setCommandsVisible([.searchFiles], settings.fileSearchEnabled)
        indexer.setEnabled(settings.fileSearchEnabled)
        guard !settings.fileSearchEnabled else { return }
        session.cancel()
        if palette.mode == .fileSearch { palette.prepare(mode: .launcher) }
    }

    func applyPolicy() {
        indexer.apply(FileSearchPolicy(
            scopes: settings.fileSearchScopes, ignorePatterns: settings.fileSearchIgnorePatterns,
            homeDirectory: FileManager.default.homeDirectoryForCurrentUser))
    }

    func searchFromLauncher(_ query: String) {
        guard settings.fileSearchEnabled, settings.fileSearchShowInLauncher,
            FileSearchQuery.answersLauncher(query) else { session.cancel(); return }
        session.search(query)
    }

    func launcherFiles(for query: String) -> [FileSearchResult] {
        guard settings.fileSearchEnabled, settings.fileSearchShowInLauncher,
            FileSearchQuery.answersLauncher(query) else { return [] }
        return Array(session.results.prefix(FileSearchQuery.launcherLimit))
    }

    func rebuildIndex() { indexer.rebuild() }

    func show() {
        guard settings.fileSearchEnabled else { return }
        indexer.refreshAccess()
        paletteCoordinator.showPalette(mode: .fileSearch)
    }

    func open(_ result: FileSearchResult) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        Task {
            do {
                _ = try await NSWorkspace.shared.open(
                    result.url, configuration: NSWorkspace.OpenConfiguration())
            } catch {
                await core.showNotice(
                    title: "Couldn’t Open \(result.name)",
                    message: error.localizedDescription,
                    symbol: result.isDirectory ? "folder" : "doc", tone: .danger)
            }
        }
    }

    func showInFinder(_ result: FileSearchResult) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        AppLauncher.showInFinder(result.url)
    }

    func copyPath(_ result: FileSearchResult) {
        Paster.copyPlainText(result.id)
        core.showMessage("Copied path")
    }
}
