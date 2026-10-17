import AppKit

@MainActor
private final class RefuseQuitDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        .terminateCancel
    }
}

@main
@MainActor
struct AppQuitTest {
    enum Failure: Error { case failed(String) }

    static func check(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure.failed(message) }
        print("PASS  \(message)")
    }

    static func fixture() {
        let app = NSApplication.shared
        let delegate = RefuseQuitDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { app.run() }
    }

    static func main() async throws {
        if CommandLine.arguments.contains("--quit-fixture") {
            fixture()
            return
        }
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("tinycast-quit-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: root) }
        let appURL = root.appendingPathComponent("Quit Fixture.app")
        let contents = appURL.appendingPathComponent("Contents")
        let macOS = contents.appendingPathComponent("MacOS")
        try fm.createDirectory(at: macOS, withIntermediateDirectories: true)
        try fm.copyItem(
            at: URL(fileURLWithPath: CommandLine.arguments[0]), to: macOS.appendingPathComponent("Fixture"))
        let bundleID = "test.tinycast.quit.\(UUID().uuidString.lowercased())"
        let plist: [String: Any] = [
            "CFBundleIdentifier": bundleID, "CFBundleExecutable": "Fixture",
            "CFBundleName": "Tinycast Quit Fixture", "CFBundlePackageType": "APPL", "LSUIElement": true
        ]
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            .write(to: contents.appendingPathComponent("Info.plist"))
        let signing = Process()
        signing.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        signing.arguments = ["--force", "--sign", "-", appURL.path]
        try signing.run()
        signing.waitUntilExit()
        try check(signing.terminationStatus == 0, "fixture is locally signed")
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        config.arguments = ["--quit-fixture"]
        let app = try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
        defer { if !app.isTerminated { app.forceTerminate() } }
        try await Task.sleep(for: .milliseconds(300))
        try check(app.bundleIdentifier == bundleID, "only the isolated fixture is targeted")
        try check(AppLauncher.quit(bundleID: bundleID), "normal quit finds the running fixture")
        try await Task.sleep(for: .milliseconds(300))
        try check(!app.isTerminated, "normal quit lets the fixture refuse termination")
        try check(AppLauncher.quit(bundleID: bundleID, force: true), "force quit finds the running fixture")
        for _ in 0..<100 {
            if app.isTerminated { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        try check(app.isTerminated, "force quit terminates the refusing fixture")
        try check(!AppLauncher.quit(bundleID: bundleID, force: true), "a stopped app is a no-op")
    }
}
