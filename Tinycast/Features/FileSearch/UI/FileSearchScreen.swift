import SwiftUI

struct FileSearchScreen: PaletteScreen {
    let session: FileSearchSession
    let core: AppCore
    let vm: PaletteState
    let openActions: () -> Void

    var rows: [FileSearchResult] { session.results }

    var primaryActionTitle: String {
        guard let result = result(at: vm.selection) else { return "Open File" }
        return result.isDirectory ? "Open Folder" : "Open File"
    }

    private func result(at selection: Int) -> FileSearchResult? {
        rows.indices.contains(selection) ? rows[selection] : nil
    }

    func headerAccessory(at selection: Int, focus: FocusState<String?>.Binding) -> PaletteHeaderAccessory? {
        PaletteHeaderAccessory(width: 140, fieldNames: [], firstIncompleteField: nil, view: AnyView(
            Picker("File Type", selection: Binding(get: { vm.fileSearchFilter }, set: {
                vm.fileSearchFilter = $0
                vm.selection = 0
                session.search(vm.query, filter: $0)
            })) {
                ForEach(FileSearchFilter.allCases, id: \.self) { Text($0.title).tag($0) }
            }.labelsHidden()
        ))
    }

    func actions(at selection: Int) -> PopoverMenuContent? {
        guard let result = result(at: selection) else { return nil }
        return FileSearchActionsMenu.content(result: result, core: core)
    }

    func activate(at selection: Int) {
        guard let result = result(at: selection) else { return }
        core.fileSearchCoordinator.open(result)
    }

    func secondary(at selection: Int) -> Bool {
        guard let result = result(at: selection) else { return false }
        core.fileSearchCoordinator.showInFinder(result)
        return true
    }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        AnyView(content(selection: selection, scroll: scroll))
    }

    @ViewBuilder
    private func content(selection: Int, scroll: ScrollIntent) -> some View {
        if core.fileIndexer.status == .needsAccess {
            VStack {
                EmptyResults(text: "Full Disk Access required")
                Button("Open Privacy Settings…") { Permissions.openFullDiskAccessSettings() }
            }
        } else if rows.isEmpty {
            EmptyResults(text: session.state == .ready ? "No files found" : "Indexing files…")
        } else {
            HStack(spacing: 0) {
            FileSearchList(
                results: rows,
                selectedID: rows.indices.contains(selection) ? rows[selection].id : nil,
                scroll: scroll,
                onSelect: { file in vm.selection = rows.firstIndex(of: file) ?? 0 },
                onActivate: { core.fileSearchCoordinator.open($0) },
                onActions: { result in
                    if let index = rows.firstIndex(of: result) { vm.selection = index }
                    openActions()
                })
                .frame(width: Theme.Size.clipboardListWidth)
                Divider()
                FileSearchPreview(result: result(at: selection))
            }
        }
    }
}

@MainActor
enum FileSearchActionsMenu {
    static func content(result: FileSearchResult, core: AppCore) -> PopoverMenuContent {
        PopoverMenuContent(
            header: result.name,
            items: [
                PopoverMenuItem(
                    title: result.isDirectory ? "Open Folder" : "Open File",
                    systemImage: result.isDirectory ? "folder" : "doc", shortcut: "↵"
                ) { core.fileSearchCoordinator.open(result) },
                PopoverMenuItem(
                    title: "Show in Finder", systemImage: "folder", shortcut: "⌘↵"
                ) { core.fileSearchCoordinator.showInFinder(result) },
                PopoverMenuItem(
                    title: "Copy Path", systemImage: "doc.on.clipboard"
                ) { core.fileSearchCoordinator.copyPath(result) }
            ])
    }
}
