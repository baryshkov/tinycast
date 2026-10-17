import Foundation

struct SettingsSearchEntry: Identifiable, Hashable, Sendable {
    let tab: SettingsTab
    /// Where picking this result lands; nil for the pane itself, which is its own result.
    let target: SettingsTarget?
    let title: String
    let keywords: [String]

    /// Taking the pane from the target is what makes a row filed under the wrong pane unwritable.
    private init(_ target: SettingsTarget, _ title: String, _ keywords: [String]) {
        self.tab = target.tab
        self.target = target
        self.title = title
        self.keywords = keywords
    }

    /// One setting, which its pane marks with a matching `SettingsRowTitle`.
    init(_ anchor: SettingsAnchor, _ title: String, keywords: [String] = []) {
        self.init(.row(anchor, title), title, keywords)
    }

    /// A whole group, for a result no single row answers — a list, or a section's master switch.
    init(group anchor: SettingsAnchor, _ title: String, keywords: [String] = []) {
        self.init(.section(anchor), title, keywords)
    }

    init(pane: SettingsTab, keywords: [String] = []) {
        self.tab = pane
        self.target = nil
        self.title = pane.title
        self.keywords = keywords
    }

    init(pane: SettingsTab, title: String) {
        self.tab = pane
        self.target = nil
        self.title = title
        self.keywords = [pane.title]
    }

    var anchor: SettingsAnchor? { target?.anchor }

    var id: String { "\(tab.title)/\(anchor?.title ?? "")/\(title)" }

    var breadcrumb: String {
        guard let anchor, anchor.title != tab.title else { return tab.title }
        return "\(tab.title) › \(anchor.title)"
    }
}

/// What Settings offers to search. Hand-written: a `Form` can't be asked what rows it holds, so a
/// new row is searchable only once it is listed here.
enum SettingsSearchCatalog {
    struct Query: Sendable {
        let terms: [FuzzyMatch.Query]

        init(_ raw: String) {
            terms = raw.split(whereSeparator: \Character.isWhitespace).map {
                FuzzyMatch.Query(String($0))
            }
        }

        var isEmpty: Bool { terms.isEmpty }
    }

    static func results(for raw: String, limit: Int = 50) -> [SettingsSearchEntry] {
        let query = Query(raw)
        guard !query.isEmpty else { return [] }
        // Catalog order is the tie-break, so results don't reshuffle between equal-scoring rows.
        return
            entries
            .enumerated()
            .compactMap { item -> (entry: SettingsSearchEntry, score: Int, rank: Int)? in
                guard let score = score(query, item.element) else { return nil }
                return (item.element, score, item.offset)
            }
            .sorted { $0.score != $1.score ? $0.score > $1.score : $0.rank < $1.rank }
            .prefix(limit)
            .map(\.entry)
    }

    /// Every term must land somewhere; a term matched in the title outranks one found off it.
    private static func score(_ query: Query, _ entry: SettingsSearchEntry) -> Int? {
        var titleScore = 0
        var titleMatches = 0
        for term in query.terms {
            if let match = FuzzyMatch.match(term, candidate: entry.title) {
                titleMatches += 1
                titleScore += match.score
                continue
            }
            guard
                entry.keywords.contains(where: { FuzzyMatch.match(term, candidate: $0) != nil })
                    || FuzzyMatch.match(term, candidate: entry.breadcrumb) != nil
            else { return nil }
        }

        let band: Int
        if titleMatches == query.terms.count {
            band = 2_000_000
        } else if titleMatches > 0 {
            band = 1_000_000
        } else {
            band = 0
        }
        // A pane outranks its own rows, so a bare "clipboard" lands on the pane rather than a row.
        return band + titleScore + (entry.anchor == nil ? 500_000 : 0)
    }

    // MARK: - The index
    // Pane order, then section order within a pane, so this reads as a table of contents.

    static let entries: [SettingsSearchEntry] =
        SettingsTab.allCases.map { SettingsSearchEntry(pane: $0) } + fields + [
            .init(
                group: .generalSearch, "Search",
                keywords: ["fuzzy", "ranking", "suggestions", "sensitivity", "поиск"]),
            .init(group: .generalSearch, "Interface size", keywords: ["scale", "large", "размер", "шрифт"]),
            .init(
                group: .backupSettingsFile, "Sync settings file",
                keywords: ["settings.json", "config", "настройки"]),
            .init(group: .fileSearchFileSearch, "Enable File Search", keywords: ["files", "index", "файлы"]),
            .init(
                group: .windowManagementCustomSizes, "Custom window sizes", keywords: ["size", "размер окон"]),
            .init(group: .windowManagementLayouts, "Window Layouts", keywords: ["capture", "раскладка"]),
            .init(group: .windowManagementRooms, "Rooms", keywords: ["projects", "комнаты"]),
            .init(
                group: .backupImportFromRaycast, "Import from Raycast",
                keywords: ["rayconfig", "migration", "импорт"])
        ]

    private static let fields: [SettingsSearchEntry] = [
        .init(pane: .general, title: "App Launcher"),
        .init(pane: .general, title: "Global Shortcuts"),
        .init(pane: .general, title: "Summon the fuzzy app launcher."),
        .init(pane: .general, title: "Show Suggestions"),
        .init(pane: .general, title: "Search Sensitivity"),
        .init(pane: .general, title: "Interface size"),
        .init(pane: .general, title: "Enable Window Switcher"),
        .init(pane: .general, title: "Switch Windows"),
        .init(pane: .general, title: "Switch Windows Backwards"),
        .init(pane: .general, title: "Learned ranking"),
        .init(pane: .general, title: "Hyper Key"),
        .init(pane: .general, title: "Does Nothing"),
        .init(pane: .general, title: "Trigger Escape"),
        .init(pane: .general, title: "Quick Press"),
        .init(pane: .general, title: "Include Shift (⇧)"),
        .init(pane: .general, title: "Theme"),
        .init(pane: .general, title: "Compact mode"),
        .init(pane: .general, title: "Show favorites in compact mode"),
        .init(pane: .general, title: "Follow the cursor across displays"),
        .init(pane: .general, title: "Drag to reposition"),
        .init(pane: .general, title: "Appearance"),
        .init(pane: .general, title: "Launch at login"),
        .init(pane: .general, title: "Start Tinycast automatically when you log in."),
        .init(pane: .general, title: "Show in menu bar"),
        .init(pane: .general, title: "Pop to Root Search"),
        .init(pane: .general, title: "None"),
        .init(pane: .general, title: "Auto-switch input source"),
        .init(pane: .general, title: "General"),
        .init(pane: .applications, title: "Search Scopes"),
        .init(pane: .applications, title: "Folders searched when indexing applications."),
        .init(pane: .commands, title: "Delete"),
        .init(pane: .fileSearch, title: "Enable File Search"),
        .init(pane: .fileSearch, title: "Show Files in Launcher"),
        .init(pane: .fileSearch, title: "File Search"),
        .init(pane: .fileSearch, title: "Commands"),
        .init(pane: .fileSearch, title: "Search Scopes"),
        .init(pane: .fileSearch, title: "Ignore Patterns"),
        .init(pane: .notes, title: "Enable Notes"),
        .init(pane: .notes, title: "Notes"),
        .init(pane: .notes, title: "Commands"),
        .init(pane: .snippets, title: "Delete"),
        .init(pane: .snippets, title: "New Snippet"),
        .init(pane: .snippets, title: "Snippets Folder"),
        .init(pane: .snippets, title: "Library"),
        .init(pane: .snippets, title: "Template"),
        .init(pane: .windowManagement, title: "Show layouts in launcher"),
        .init(pane: .windowManagement, title: "New Layout"),
        .init(pane: .windowManagement, title: "Create Layout from Current Windows"),
        .init(pane: .windowManagement, title: "Show rooms in launcher"),
        .init(pane: .windowManagement, title: "New Room"),
        .init(pane: .windowManagement, title: "New Custom Size"),
        .init(pane: .windowManagement, title: "Enable Window Management"),
        .init(pane: .windowManagement, title: "Show Window Commands in Launcher"),
        .init(pane: .windowManagement, title: "Delete"),
        .init(pane: .windowManagement, title: "Cycling"),
        .init(pane: .windowManagement, title: "Gap between windows"),
        .init(pane: .windowManagement, title: "Between tiled windows and screen edges."),
        .init(pane: .windowManagement, title: "Shortcut preset"),
        .init(pane: .windowManagement, title: "Choose…"),
        .init(pane: .windowManagement, title: "Options"),
        .init(pane: .clipboard, title: "Clipboard History"),
        .init(pane: .clipboard, title: "Global Shortcuts"),
        .init(pane: .clipboard, title: "Open the clipboard history browser."),
        .init(pane: .clipboard, title: "Keep history for"),
        .init(pane: .clipboard, title: "History"),
        .init(pane: .clipboard, title: "Disabled Applications"),
        .init(pane: .clipboard, title: "Clear history"),
        .init(pane: .emoji, title: "Emoji & Symbols"),
        .init(pane: .emoji, title: "Global Shortcuts"),
        .init(pane: .emoji, title: "Summon the emoji and symbols palette."),
        .init(pane: .emoji, title: "Emoji Skin Tone"),
        .init(pane: .emoji, title: "Appearance"),
        .init(pane: .backup, title: "Sync settings file"),
        .init(pane: .backup, title: "Export Settings"),
        .init(pane: .backup, title: "Import Settings"),
        .init(pane: .backup, title: "Tinycast"),
        .init(pane: .backup, title: "Raycast Export"),
        .init(pane: .backup, title: "Passphrase"),
        .init(pane: .backup, title: "Import"),
        .init(pane: .backup, title: "Choose what to bring over, then import."),
        .init(pane: .backup, title: "Import from Raycast")
    ]

}
