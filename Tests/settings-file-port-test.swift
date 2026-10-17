import Foundation
import Observation

@MainActor @Observable final class FileSettingsFixture {
    var theme = "dark"
    var compact = false
}

@main @MainActor struct SettingsFilePortTest {
    static func main() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(
            "tinycast-settings-port-" + UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let url = root.appendingPathComponent("settings.json")
        let state = FileSettingsFixture()
        var issues: [SettingsFileIssue] = []
        let repository = SettingsFileRepository(
            fileURL: url,
            bindings: [
                SettingsFileBinding(.appearance, state, \.theme),
                SettingsFileBinding(.compactMode, state, \.compact)
            ])
        repository.onIssues = { issues = $0 }
        repository.start(importing: false)
        var decoded = try SettingsFileFormat.parse(Data(contentsOf: url))
        precondition(decoded.values[.appearance] == .string("dark"))
        state.theme = "light"
        try await Task.sleep(for: .milliseconds(500))
        repository.flush()
        decoded = try SettingsFileFormat.parse(Data(contentsOf: url))
        precondition(decoded.values[.appearance] == .string("light"))
        let edited = SettingsFileFormat.render([.appearance: .string("system"), .compactMode: .bool(true)])
        try edited.write(to: url, options: .atomic)
        try await Task.sleep(for: .milliseconds(600))
        precondition(state.theme == "system" && state.compact)
        try Data("{broken".utf8).write(to: url, options: .atomic)
        try await Task.sleep(for: .milliseconds(600))
        precondition(state.theme == "system" && state.compact && !issues.isEmpty)
        try SettingsFileFormat.render([.appearance: .number(42)]).write(to: url, options: .atomic)
        try await Task.sleep(for: .milliseconds(600))
        precondition(state.theme == "system")
        precondition(!SettingsFileKey.allCases.contains { ["ai", "mcp", "calendar"].contains($0.section) })
        precondition(
            AppPaths.settingsFile(bundleID: "com.tinycast.app.dev").path.hasSuffix(
                "tinycast-dev/settings.json"))
        precondition(
            AppPaths.settingsFile(bundleID: "com.tinycast.app").path.hasSuffix("tinycast/settings.json"))
        print("Settings file round-trip, atomic saves, invalid edits and channel isolation passed")
    }
}
