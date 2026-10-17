import AppKit

struct AppEntry: Identifiable, Hashable, Sendable {
    enum Kind: String, CaseIterable, Sendable {
        case application
        case systemSettings
        case command
        case customCommand
        case snippet
        case systemAction
        case windowCommand
        case quicklink
        case extensionCommand

        var descriptor: KindDescriptor {
            switch self {
            case .application:
                return KindDescriptor(
                    label: "Application", sectionTitle: "Applications",
                    openVerb: "Open Application", canRevealInFinder: true, isSymbolIcon: false)
            case .systemSettings:
                return KindDescriptor(
                    label: "System Setting", sectionTitle: "System Settings",
                    openVerb: "Open System Setting", canRevealInFinder: true, isSymbolIcon: false)
            case .command:
                return KindDescriptor(
                    label: "Command", sectionTitle: "Commands",
                    openVerb: "Run Command", canRevealInFinder: false, isSymbolIcon: true)
            case .customCommand:
                return KindDescriptor(
                    label: "Custom Command", sectionTitle: "Custom Commands",
                    openVerb: "Run Custom Command", canRevealInFinder: false, isSymbolIcon: true)
            case .snippet:
                return KindDescriptor(
                    label: "Snippet", sectionTitle: "Snippets",
                    openVerb: "Paste Snippet", canRevealInFinder: true, isSymbolIcon: true)
            case .systemAction:
                return KindDescriptor(
                    label: "System Action", sectionTitle: "System Actions",
                    openVerb: "Run System Action", canRevealInFinder: false, isSymbolIcon: true)
            case .windowCommand:
                return KindDescriptor(
                    label: "Window Command", sectionTitle: "Window Management",
                    openVerb: "Move Window", canRevealInFinder: false, isSymbolIcon: true)
            case .quicklink:
                return KindDescriptor(
                    label: "Quicklink", sectionTitle: "Quicklinks",
                    openVerb: "Open Quicklink", canRevealInFinder: false, isSymbolIcon: true)
            case .extensionCommand:
                // The label is per-entry (the owning extension's title), so this is only the fallback.
                return KindDescriptor(
                    label: "Extension", sectionTitle: "Extensions",
                    openVerb: "Run Command", canRevealInFinder: false, isSymbolIcon: true)
            }
        }
    }

    /// Everything that is fixed per kind. A new `Kind` case fails to build until it names all five.
    struct KindDescriptor: Sendable {
        let label: String
        let sectionTitle: String
        let openVerb: String
        let canRevealInFinder: Bool
        let isSymbolIcon: Bool
    }

    let id: String  // file path (or "command:…" id) — always unique
    let name: String  // clean display name, never includes ".app"
    let url: URL
    let bundleID: String?
    let kind: Kind
    /// Extra strings matching as strongly as the name; empty for every kind but snippets.
    var matchAliases: [String] = []
    var primaryInstallationID: String?
    var subtitle: String?
    var installedAt: Date?
    var search = SearchProfile.unnamed
    var isPrimaryInstallation: Bool { primaryInstallationID == nil || primaryInstallationID == id }
    /// Per-item symbol, for the one kind whose glyph is the user's choice. Nil elsewhere.
    var symbolName: String?
    /// Spotlight's `kMDItemAlternateNames`, ranked below the display name. Applications only.
    var alternateNames: [String] = []
    /// `CFBundleExecutable`, matched literally as a last resort. Applications only.
    var executableName: String?
    /// Set by the feature that produced the entry when its glyph isn't derivable from `kind`.
    var iconOverride: EntryIcon?
    /// A per-entry label where the kind's own reads too flat — an extension's title, say.
    var labelOverride: String?

    /// Stable identity for learned ranking, favorites, and other per-entry preferences.
    var preferenceKey: String { bundleID ?? id }

    var searchFields: SearchFields {
        SearchFields(
            names: [name] + matchAliases, alternateNames: alternateNames,
            bundleID: bundleID, executableName: executableName)
    }

    var kindLabel: String { labelOverride ?? kind.descriptor.label }

    /// The hotkey action for this entry, or nil when the entry has no addressable action.
    var hotKeyAction: HotKeyAction? {
        switch kind {
        case .command:
            return CommandCatalog.command(for: self)?.hotKeyAction
        case .application:
            return bundleID.map { .app(bundleID: $0) }
        case .systemSettings:
            return bundleID.map { .settingsPane(bundleID: $0) }
        case .customCommand:
            return CustomCommand.id(fromEntryID: id).map { .customCommand(id: $0) }
        case .systemAction:
            return SystemActionCatalog.action(forEntryID: id).map { .systemAction(id: $0.id) }
        case .windowCommand:
            if let uuid = CustomWindowSize.id(fromEntryID: id) { return .customWindowSize(id: uuid) }
            if let uuid = WindowLayout.id(fromEntryID: id) { return .windowLayout(id: uuid) }
            if let uuid = Room.id(fromEntryID: id) { return .windowRoom(id: uuid) }
            return WindowCommandCatalog.command(forEntryID: id).map { .windowCommand(id: $0.id) }
        case .quicklink:
            return Quicklink.id(fromEntryID: id).map { .quicklink(id: $0) }
        case .snippet, .extensionCommand:
            return nil
        }
    }

    /// Synthetic entries have no file to reveal; a destination is its record's own action.
    var canRevealInFinder: Bool { kind.descriptor.canRevealInFinder }

    /// What this row draws, and the only thing any icon path needs to ask.
    var iconSource: EntryIcon { iconOverride ?? defaultIcon }

    /// Derived from the kind alone: synthetic entries get a symbol tile, everything else its file.
    private var defaultIcon: EntryIcon {
        guard kind.descriptor.isSymbolIcon else { return .file }
        return .symbol(symbolName ?? kindSymbol)
    }

    private var kindSymbol: String {
        switch kind {
        case .quicklink: return Quicklink.sfSymbol
        case .snippet: return "text.quote"
        case .customCommand: return CustomCommand.sfSymbol
        case .command: return CommandCatalog.command(for: self)?.sfSymbol ?? "questionmark"
        case .systemAction: return SystemActionCatalog.action(forEntryID: id)?.sfSymbol ?? "questionmark"
        case .windowCommand:
            return WindowCommandCatalog.command(forEntryID: id)?.sfSymbol ?? "questionmark"
        case .application, .systemSettings, .extensionCommand: return "questionmark"
        }
    }

    /// Main-actor because it subscribes the calling view; every caller is a `body`.
    @MainActor var icon: NSImage {
        IconCache.observeStyle()
        return IconCache.icon(for: iconSource, fileURL: url)
    }

    /// Icon identity for a row's async load: re-skinning changes the glyph while `id` stays put.
    var iconKey: String { "\(id)|\(iconSource)" }
}

extension AppEntry.Kind {
    /// The descriptors' own words, lowercased once, so a keystroke costs a lookup and not a scan.
    private static let byCategoryName: [String: AppEntry.Kind] = allCases.reduce(into: [:]) {
        $0[$1.descriptor.sectionTitle.lowercased()] = $1
        $0[$1.descriptor.label.lowercased()] = $1
    }

    /// The category a query names outright. Exact only — a prefix would take a word from an entry.
    static func named(by query: String) -> AppEntry.Kind? {
        byCategoryName[query.trimmingCharacters(in: .whitespaces).lowercased()]
    }
}

extension AppEntry {
    init(_ command: WindowCommand) {
        self.init(
            id: command.entryID, name: command.name,
            url: URL(string: "tinycast://window-command/" + command.id.rawValue)!, bundleID: nil,
            kind: .windowCommand)
    }

    init(_ size: CustomWindowSize) {
        self.init(
            id: size.entryID, name: size.name,
            url: URL(string: "tinycast://window-size/" + size.id.uuidString)!, bundleID: nil,
            kind: .windowCommand)
    }
    init(_ layout: WindowLayout) {
        self.init(
            id: layout.entryID, name: layout.name,
            url: URL(string: "tinycast://window-layout/" + layout.id.uuidString)!, bundleID: nil,
            kind: .windowCommand, symbolName: layout.iconSymbol)
    }
    init(_ room: Room) {
        self.init(
            id: room.entryID, name: room.name,
            url: URL(string: "tinycast://window-room/" + room.id.uuidString)!, bundleID: nil,
            kind: .windowCommand)
    }

}

@MainActor
@Observable
final class AppIndex {
    private(set) var apps: [AppEntry] = []

    private var snippetEntries: [AppEntry] = []

    private struct MatchKey: Equatable {
        let query: String
        let entriesRevision: Int
        let rankingRevision: Int
        let aliasRevision: Int
        let sensitivity: SearchSensitivity
    }

    private struct ResultsKey: Equatable {
        let query: String
        let entriesRevision: Int
        let rankingRevision: Int
        let aliasRevision: Int
        let sensitivity: SearchSensitivity
        let visibilityRevision: Int
        let favoritesRevision: Int
        let hotKeysRevision: Int
        let showsSuggestions: Bool
        let minute: Int
    }

    /// Repeated renders for the same query reuse the ranking instead of re-matching every frame.
    @ObservationIgnored private var matchMemo = Memo<MatchKey, [AppEntry]>()
    @ObservationIgnored private var resultsMemo = Memo<ResultsKey, [AppEntry]>()
    /// Bumped whenever `apps` changes, so both memos above name the entry set they were built from.
    private var entriesRevision = 0

    private static let systemActionEntries: [AppEntry] = SystemActionCatalog.all
        .map { command in
            AppEntry(
                id: command.entryID, name: command.name,
                url: URL(string: "tinycast://system-action/" + command.id.rawValue)!,
                bundleID: nil, kind: .systemAction)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

    private static let allWindowCommandEntries: [AppEntry] = WindowCommandCatalog.all
        .map { command in
            AppEntry(
                id: command.entryID, name: command.name,
                url: URL(string: "tinycast://window-command/" + command.id.rawValue)!,
                bundleID: nil, kind: .windowCommand)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

    private var discoveredEntries: [AppEntry] = []
    private var customCommandEntries: [AppEntry] = []
    private var windowCommandEntries: [AppEntry] = []
    private var quicklinkEntries: [AppEntry] = []
    private var extensionEntries: [AppEntry] = []
    /// The catalog's commands a disabled feature hides; the Commands slice is recomputed from it.
    private var unlistedCommands = Set<CommandID>()
    private var sizeEntries: [AppEntry] = []
    private var layoutEntries: [AppEntry] = []
    private var roomEntries: [AppEntry] = []
    private var hiddenCommands: Set<CommandID> = []
    private var alternateNameCache = BundleNameCache()
    private var paneCache: SettingsPaneScanner.Cache?
    private var isRefreshing = false
    /// Set when a refresh lands mid-scan, so a scope edit is never silently dropped.
    private var refreshPending = false
    private let ranking: LauncherRankingStore
    private let aliases: AliasStore
    private var settings: AppSettings?

    init(ranking: LauncherRankingStore, aliases: AliasStore) {
        self.ranking = ranking
        self.aliases = aliases
    }

    /// The always-relevant built-ins, plus whatever a disabled feature has not hidden.
    private var commandEntries: [AppEntry] {
        CommandCatalog.all.filter {
            guard let command = CommandCatalog.command(for: $0) else { return true }
            return !hiddenCommands.contains(command) && !unlistedCommands.contains(command)
        }
    }

    /// A feature's commands leave the Commands slice when the feature is off; `visible` restores them.
    func setCommandsListed(_ commands: Set<CommandID>, _ listed: Bool) {
        unlistedCommands = listed ? unlistedCommands.subtracting(commands) : unlistedCommands.union(commands)
        publishEntries()
    }
    func setCustomWindowSizes(_ values: [CustomWindowSize]) {
        sizeEntries = values.map(AppEntry.init); publishEntries()
    }
    func setWindowLayouts(_ values: [WindowLayout]) {
        layoutEntries = values.map(AppEntry.init); publishEntries()
    }
    func setWindowRooms(_ values: [Room]) { roomEntries = values.map(AppEntry.init); publishEntries() }

    func setCommandsVisible(_ commands: Set<CommandID>, _ visible: Bool) {
        let updated = visible ? hiddenCommands.subtracting(commands) : hiddenCommands.union(commands)
        guard updated != hiddenCommands else { return }
        hiddenCommands = updated
        publishEntries()
    }

    /// Replaces the command slice without rescanning, so Settings edits land at once.
    func setCustomCommands(_ commands: [CustomCommand]) {
        let entries = commands.map { command in
            AppEntry(
                id: command.entryID, name: command.name,
                url: URL(string: "tinycast://custom-command/" + command.id.uuidString)!,
                bundleID: nil, kind: .customCommand)
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard entries != customCommandEntries else { return }
        customCommandEntries = entries
        publishEntries()
    }

    /// Replaces the quicklink slice; a toggle can't split its entries from their section.
    func setQuicklinks(_ quicklinks: [Quicklink]) {
        let entries =
            quicklinks
            .filter(\.showsInRootSearch)
            .sorted(by: Quicklink.precedes)
            .map { quicklink in
                AppEntry(
                    id: quicklink.entryID, name: quicklink.name,
                    url: URL(string: "tinycast://quicklink/" + quicklink.id.uuidString)!,
                    bundleID: nil, kind: .quicklink,
                    symbolName: quicklink.iconSymbol
                        ?? QuicklinkDestination.detect(quicklink.link)?.defaultSymbol)
            }
        guard entries != quicklinkEntries else { return }
        quicklinkEntries = entries
        publishEntries()
    }

    /// Replaces the extension-command slice. Called by `ExtensionManager` whenever the installed set,
    /// or an extension's chosen appearance, changes.
    func setExtensionCommands(_ entries: [AppEntry]) {
        guard entries != extensionEntries else { return }
        extensionEntries = entries
        publishEntries()
    }

    /// Shows or hides the window-command slice; the catalog itself is static.
    func setWindowCommandsVisible(_ visible: Bool) {
        let entries = visible ? Self.allWindowCommandEntries : []
        guard entries != windowCommandEntries else { return }
        windowCommandEntries = entries
        publishEntries()
    }

    func updateSnippets(_ records: [StoredSnippet]) {
        let entries =
            records
            .filter { $0.snippet.isEnabled }
            .map { record in
                AppEntry(
                    id: "snippet:\(record.id)",
                    name: record.snippet.name,
                    url: record.fileURL,
                    bundleID: nil,
                    kind: .snippet,
                    matchAliases: [record.snippet.keyword].compactMap { $0 })
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        guard entries != snippetEntries else { return }
        snippetEntries = entries
        publishEntries()
    }

    /// Wires the scopes, re-indexing on edit rather than waiting for the next open.
    func start(settings: AppSettings) {
        self.settings = settings
        observeSearchScopes()
    }

    /// Fires synchronously on main before the write lands, so the task re-arms, then rescans.
    private func observeSearchScopes() {
        withObservationTracking {
            _ = settings?.searchScopes
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.observeSearchScopes()
                await self.refresh()
            }
        }
    }

    /// Re-scan on every open; reopens collapse, and an unchanged set does no UI work.
    func refresh() async {
        guard !isRefreshing else {
            refreshPending = true
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        repeat {
            refreshPending = false
            let scopes = settings?.searchScopes ?? SearchScopes.defaults
            let reusing = alternateNameCache
            let reusingPanes = paneCache
            let (found, cache, panes) = await Task.detached(priority: .utility) {
                AppIndex.scan(
                    scopes: scopes,
                    cache: BundleNameCache(reusing: reusing, languages: Locale.preferredLanguages),
                    paneCache: reusingPanes)
            }.value
            alternateNameCache = cache
            paneCache = panes
            guard found != discoveredEntries else { continue }
            discoveredEntries = found
            publishEntries()
        } while refreshPending
    }

    nonisolated private static func scan(
        scopes: [String], cache: BundleNameCache, paneCache: SettingsPaneScanner.Cache?
    ) -> ([AppEntry], BundleNameCache, SettingsPaneScanner.Cache?) {
        Signposts.interval("AppIndex.scan") {
            var cache = cache
            var indexByBundleID: [String: Int] = [:]
            var paths = Set<String>()
            var result: [AppEntry] = []
            for url in SearchScopes.appBundles(in: scopes) {
                let path = url.resolvingSymlinksInPath().standardizedFileURL.path
                guard paths.insert(path).inserted else { continue }
                let bundle = Bundle(url: url)
                let bundleID = bundle?.bundleIdentifier
                let fileName = EntryNaming.strippingAppExtension(url.lastPathComponent)
                // Finder's rule: LaunchServices ignores a display name the file name contradicts.
                let names = cache.names(
                    for: url, base: fileName, developmentRegion: bundle?.developmentLocalization)
                // Raw: a localized strings file can swap this array for a plain name.
                let alternates = bundle?.infoDictionary?["CFBundleAlternateNames"] as? [String] ?? []
                let declared = [bundle?.installedAppName].compactMap { $0 }
                var entry = AppEntry(
                    id: path, name: names.first ?? fileName, url: url, bundleID: bundleID, kind: .application)
                entry.subtitle = AppDisplayName.named(bundle?.infoDictionary?["CFBundleShortVersionString"])
                entry.alternateNames = Array(names.dropFirst()) + alternates
                entry.installedAt = try? url.resourceValues(forKeys: [.addedToDirectoryDateKey])
                    .addedToDirectoryDate
                if !entry.alternateNames.contains(fileName) { entry.alternateNames.append(fileName) }
                entry.alternateNames += declared
                if let bundleID {
                    if let first = indexByBundleID[bundleID] {
                        entry.primaryInstallationID = result[first].id
                        result[first].primaryInstallationID = result[first].id
                    } else {
                        indexByBundleID[bundleID] = result.count
                    }
                }
                result.append(entry)
            }
            let byName = Dictionary(grouping: result.indices) { FuzzyMatch.normalized(result[$0].name) }
            for group in byName.values {
                let byVersion = Dictionary(grouping: group) { result[$0].subtitle ?? "" }
                for index in group {
                    guard group.count > 1 || result[index].primaryInstallationID != nil else {
                        result[index].subtitle = nil
                        continue
                    }
                    if result[index].subtitle == nil
                        || (byVersion[result[index].subtitle ?? ""]?.count ?? 0) > 1
                    {
                        let folder = SearchScopes.abbreviate(
                            result[index].url.deletingLastPathComponent().path)
                        result[index].subtitle = [result[index].subtitle, folder].compactMap { $0 }
                            .joined(separator: " · ")
                    }
                }
            }
            let apps = result.sorted {
                let byName = $0.name.localizedCaseInsensitiveCompare($1.name)
                if byName != .orderedSame { return byName == .orderedAscending }
                if $0.isPrimaryInstallation != $1.isPrimaryInstallation { return $0.isPrimaryInstallation }
                return $0.id < $1.id
            }
            // Settings panes are `.appex` bundles, which carry no Spotlight alternate names.
            let (panes, panesCache) = SettingsPaneScanner.scan(cache: paneCache)
            return (apps + panes, cache, panesCache)
        }
    }

    private func publishEntries() {
        // Each slice arrives in its own display order; the slice order is the section order.
        var updated =
            discoveredEntries + extensionEntries + quicklinkEntries + snippetEntries
            + Self.systemActionEntries + windowCommandEntries + customCommandEntries
            + sizeEntries + layoutEntries + roomEntries + commandEntries
        for index in updated.indices { updated[index].search = profile(for: updated[index]) }
        guard updated != apps else { return }
        apps = updated
        entriesRevision &+= 1
    }

    /// Ranked matches, or a whole category when the query names one. Empty returns the full list.
    func matches(_ query: String, limit: Int = 200) -> [AppEntry] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return apps }
        let key = MatchKey(
            query: q, entriesRevision: entriesRevision, rankingRevision: ranking.revision,
            aliasRevision: aliases.revision, sensitivity: settings?.rootSearchSensitivity ?? .default)
        return matchMemo.value(for: key) {
            guard let kind = AppEntry.Kind.named(by: q) else { return rank(q, limit: limit) }
            return categoryListing(kind, query: q)
        }
    }

    /// A whole category, plus any entry the query names outright — `System Settings` is both. Slice
    /// order is section order, so filtering alone keeps the sections and the flat selection aligned.
    private func categoryListing(_ kind: AppEntry.Kind, query: String) -> [AppEntry] {
        apps.filter { $0.kind == kind || $0.name.caseInsensitiveCompare(query) == .orderedSame }
    }

    /// The launcher's ordered list: ranked matches minus hidden entries, favorites pinned first.
    func orderedResults(
        query: String, visibility: VisibilityStore, favorites: FavoritesStore
    ) -> [AppEntry] {
        let q = query.trimmingCharacters(in: .whitespaces)
        let key = ResultsKey(
            query: q, entriesRevision: entriesRevision, rankingRevision: ranking.revision,
            aliasRevision: aliases.revision, sensitivity: settings?.rootSearchSensitivity ?? .default,
            visibilityRevision: visibility.revision,
            favoritesRevision: favorites.revision,
            hotKeysRevision: hotKeys?.revision ?? 0,
            showsSuggestions: settings?.launcherShowsSuggestions ?? true,
            minute: Int(Date.now.timeIntervalSince1970 / 60))
        return resultsMemo.value(for: key) {
            // Filtering stays downstream of `matches` so that memo is never keyed on hidden state.
            let base = matches(q).filter(visibility.isVisible)
            guard q.isEmpty else { return base }
            let split = favorites.ordered(base.filter(\.isPrimaryInstallation))
            guard settings?.launcherShowsSuggestions ?? true else { return split.favorites + split.rest }
            let suggested = suggestions(from: split.rest)
            let selected = Set(suggested.map(\.id))
            return split.favorites + suggested + split.rest.filter { !selected.contains($0.id) }
        }
    }

    @ObservationIgnored weak var hotKeys: HotKeyManager?

    private func suggestions(from entries: [AppEntry]) -> [AppEntry] {
        let usage = ranking.snapshot()
        return LauncherSuggestions.select(
            from: entries.filter { $0.bundleID != Bundle.main.bundleIdentifier }, now: usage.now
        ) { entry in
            LauncherSuggestions.Traits(
                signals: signals(for: entry, usage: usage), installedAt: entry.installedAt,
                hasHotKey: entry.hotKeyAction.flatMap { hotKeys?.binding(for: $0) } != nil,
                priority: entry.kind == .application ? nil : 1)
        }
    }

    func suggestionCount(in entries: [AppEntry], favorites: FavoritesStore) -> Int {
        guard settings?.launcherShowsSuggestions ?? true else { return 0 }
        return suggestions(from: entries.filter { !favorites.isFavorite($0) && $0.isPrimaryInstallation })
            .count
    }

    private func profile(for entry: AppEntry) -> SearchProfile {
        var source = EntryNaming.Sources(name: entry.name)
        source.alternateTitles = entry.matchAliases + entry.alternateNames
        source.subtitle = entry.subtitle ?? entry.labelOverride
        source.keywords = [entry.bundleID, entry.executableName].compactMap { $0 }
        return EntryNaming.profile(for: source)
    }

    private func signals(for entry: AppEntry, usage: LauncherRankingStore.Snapshot) -> LauncherOrder.Signals {
        LauncherOrder.Signals(
            alias: aliases.alias(for: entry.preferenceKey).map { SearchText($0, transliterated: false) },
            usage: usage.usage(for: entry.preferenceKey), priority: entry.kind == .application ? 2 : 1,
            title: entry.name)
    }

    private func rank(_ q: String, limit: Int) -> [AppEntry] {
        Signposts.interval("AppIndex.rank") {
            let usage = ranking.snapshot()
            return LauncherOrder.ranked(
                apps, query: LauncherOrder.Query(q), sensitivity: settings?.rootSearchSensitivity ?? .default,
                limit: limit, profile: \.search, signals: { signals(for: $0, usage: usage) })
        }
    }
}
