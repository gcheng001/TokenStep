import Foundation

enum OdysseyMotionPrototypeDiagnostics {
    static let environmentKey = "TOKENSTEP_ODYSSEY_MOTION_DIAGNOSTICS_PATH"

    private static let lock = NSLock()
    private static let timestampFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func record(_ event: String, fields: [String: String] = [:]) {
        guard let path = ProcessInfo.processInfo.environment[environmentKey],
              !path.isEmpty
        else {
            return
        }

        lock.lock()
        defer { lock.unlock() }

        let fieldText = fields
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value.replacingOccurrences(of: " ", with: "_"))" }
            .joined(separator: " ")
        let line = [
            timestampFormatter.string(from: Date()),
            "uptime_ns=\(DispatchTime.now().uptimeNanoseconds)",
            "event=\(event)",
            fieldText
        ]
        .filter { !$0.isEmpty }
        .joined(separator: " ") + "\n"

        let url = URL(fileURLWithPath: path)
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if !FileManager.default.fileExists(atPath: url.path) {
                FileManager.default.createFile(atPath: url.path, contents: nil)
            }
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            if let data = line.data(using: .utf8) {
                try handle.write(contentsOf: data)
            }
            try handle.close()
        } catch {
            // P0 diagnostics are optional and must never affect the data tool.
        }
    }
}
