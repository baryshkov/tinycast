import Foundation

@main @MainActor struct BackupClipboardPortTest {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "tinycast-backup-clips-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let store = ClipboardStore(directory: root.appendingPathComponent("store"))
        let staging = root.appendingPathComponent("staging")
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        let image = staging.appendingPathComponent("unique-backup-image.png")
        let bytes = Data([137, 80, 78, 71, 13, 10, 26, 10])
        try bytes.write(to: image)
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let rows = [
            ClipboardItem(
                id: UUID(), kind: .text, text: "portable text", imagePath: nil, createdAt: date,
                sourceBundleID: "test.fixture", pinnedAt: date),
            ClipboardItem(
                id: UUID(), kind: .image, text: nil, imagePath: image.path, createdAt: date,
                sourceBundleID: nil, pinnedAt: date)
        ]
        let count = await Task.detached {
            ClipboardStore.importStoredItems(
                inDatabaseAt: store.dbURL, adoptingImagesInto: store.imagesDir, rows)
        }.value
        precondition(count == 2)
        store.load()
        precondition(store.items.count == 2 && store.items.allSatisfy(\.isPinned))
        let imported = store.items.first { $0.kind == .image }!
        precondition(
            imported.imagePath == store.imagesDir.appendingPathComponent(image.lastPathComponent).path)
        try FileManager.default.removeItem(at: staging)
        let adoptedBytes = try Data(contentsOf: URL(fileURLWithPath: imported.imagePath!))
        precondition(adoptedBytes == bytes)
        let second = await Task.detached {
            ClipboardStore.importStoredItems(
                inDatabaseAt: store.dbURL, adoptingImagesInto: store.imagesDir, rows)
        }.value
        precondition(second == 0)
        store.load()
        precondition(store.items.count == 2)
        print(
            "Clipboard archive adoption, pinned rows, staging cleanup and repeat-import deduplication passed")
    }
}
