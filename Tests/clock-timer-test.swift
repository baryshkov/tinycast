import Foundation

@main
struct ClockTimerTests {
    static func main() async throws {
        let cases: [(String, Int)] = [
            ("timer 10m", 600), ("timer 90s", 90), ("timer 1h30m", 5400),
            ("timer 10", 600), ("ТАЙМЕР 2ч 3м 4с", 7384), (" TIMER 23h59m59s ", 86399)
        ]
        for (query, seconds) in cases {
            precondition(ClockTimerRequest(query: query)?.seconds == seconds, query)
        }
        for query in ["timer", "timer 0m", "timer -1m", "timer 24h", "timer 1m2m", "timer 1.5h",
                      "timer 5m garbage", "timer 9999999999999999999999s", "time 5m", "timer 3m;open",
                      "timer 1 0", "timer 1 0m", "timer 1h 3 0m"] {
            precondition(ClockTimerRequest(query: query) == nil, query)
        }
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: folder) }
        let executable = folder.appendingPathComponent("fake-shortcuts")
        let script = """
            #!/bin/sh
            [ "$1" = run ] && [ "$2" = 'Tinycast Timer' ] && [ "$3" = --input-path ] && [ "$(cat "$4")" = 600 ]

            """
        try Data(script.utf8).write(to: executable)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: executable.path)
        let request = ClockTimerRequest(query: "timer 10m")!
        let success = await ClockTimerRunner.run(request, executable: executable)
        precondition(success == nil, "runner must pass 600 as a file input without invoking a shell")
        try Data("#!/bin/sh\necho 'Shortcut missing' >&2\nexit 2\n".utf8).write(to: executable)
        let failure = await ClockTimerRunner.run(request, executable: executable)
        precondition(failure == "Shortcut missing", "CLI failure must not look like a started timer")
        print("Clock timer parsing, bounds, injection rejection and runner contract passed")
    }
}
