import Foundation

enum ClockTimerRunner {
    static let shortcutName = "Tinycast Timer"

    static func run(
        _ request: ClockTimerRequest,
        executable: URL = URL(fileURLWithPath: "/usr/bin/shortcuts")
    ) async -> String? {
        await Task.detached(priority: .userInitiated) {
            execute(request, executable: executable)
        }.value
    }

    private static func execute(_ request: ClockTimerRequest, executable: URL) -> String? {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("tinycast-clock-" + UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        do {
            try FileManager.default.createDirectory(
                at: folder, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            let input = folder.appendingPathComponent("seconds.txt")
            let output = folder.appendingPathComponent("output.txt")
            try Data(String(request.seconds).utf8).write(to: input)
            FileManager.default.createFile(atPath: output.path, contents: nil)
            let handle = try FileHandle(forWritingTo: output)
            defer { try? handle.close() }
            let process = Process()
            process.executableURL = executable
            process.arguments = ["run", shortcutName, "--input-path", input.path]
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = handle
            process.standardError = handle
            let exit = try process.runObservingExit()
            exit.wait()
            guard process.terminationReason == .exit, process.terminationStatus == 0 else {
                let reader = try FileHandle(forReadingFrom: output)
                defer { try? reader.close() }
                let message = (String(data: try reader.read(upToCount: 2048) ?? Data(), encoding: .utf8) ?? "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return message.isEmpty ? "Clock could not start the timer." : message
            }
            return nil
        } catch {
            return error.localizedDescription
        }
    }
}
