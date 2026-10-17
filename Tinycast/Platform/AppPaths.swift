import Foundation

/// The per-channel storage roots. Keyed by bundle id so a Dev build never shares a stable's dirs.
enum AppPaths {
    static func caches(
        bundleID: String = Bundle.main.bundleIdentifier ?? "com.tinycast.app"
    ) -> URL {
        root(.cachesDirectory, bundleID: bundleID)
    }

    static func applicationSupport(
        bundleID: String = Bundle.main.bundleIdentifier ?? "com.tinycast.app"
    ) -> URL {
        root(.applicationSupportDirectory, bundleID: bundleID)
    }

    static func settingsFile(bundleID: String = Bundle.main.bundleIdentifier ?? "com.tinycast.app") -> URL {
        let channel = bundleID == "com.tinycast.app" ? "tinycast" : "tinycast-dev"
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".config/" + channel + "/settings.json")
    }

    private static func root(
        _ directory: FileManager.SearchPathDirectory, bundleID: String
    ) -> URL {
        let url = FileManager.default
            .urls(for: directory, in: .userDomainMask)[0]
            .appendingPathComponent(bundleID, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
