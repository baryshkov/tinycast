import AppKit

@MainActor
enum ClipboardManager {
    static let internalType = NSPasteboard.PasteboardType("test.tinycast.internal")
}

enum Permissions {
    static func ensureAccessibility() -> Bool {
        fatalError("This test must never post a global keystroke or request permissions")
    }
}

@main
@MainActor
struct ClipboardPasteboardTest {
    static func main() async throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("tinycast-pasteboard-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = ClipboardStore(directory: dir)
        let bytes = Data("test image bytes".utf8)
        store.addImage(bytes, sourceBundleID: nil)
        for _ in 0..<100 {
            if !store.items.isEmpty { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        precondition(!store.items.isEmpty, "the test image is stored")
        let item = store.items[0]
        let board = NSPasteboard.withUniqueName()
        defer { board.releaseGlobally() }
        precondition(Paster.write(item, store: store, to: board), "a stored image can be copied")
        precondition(board.data(forType: .png) == bytes, "rich text receivers retain PNG data")
        let urls = board.readObjects(forClasses: [NSURL.self]) as? [URL]
        precondition(urls?.first?.path == item.imagePath, "terminal receivers get the image file path")
        precondition(board.string(forType: .string) == nil, "no text overrides the image")
        precondition(board.types?.contains(ClipboardManager.internalType) == true, "own writes are marked")

        try FileManager.default.removeItem(atPath: item.imagePath ?? "")
        let before = board.changeCount
        precondition(!Paster.write(item, store: store, to: board), "a vanished image is refused")
        precondition(board.changeCount == before, "a failed copy preserves the pasteboard")

        store.addText("plain text", sourceBundleID: nil)
        precondition(Paster.write(store.items[0], store: store, to: board), "text still writes")
        precondition(board.string(forType: .string) == "plain text", "text contents are retained")
        precondition(board.data(forType: .fileURL) == nil, "text does not carry a stale image URL")
        print("Clipboard pasteboard checks passed")
    }
}
