import Foundation

extension UsageCollector {
    static func zstdSessionFiles(under root: URL, modifiedSince cutoffDate: Date? = nil) -> [URL] {
        guard FileManager.default.fileExists(atPath: root.path),
              let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
              )
        else {
            return []
        }

        return enumerator.compactMap { item in
            guard let url = item as? URL,
                  url.lastPathComponent == "session.jsonl.zstd",
                  let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey]),
                  values.isRegularFile == true
            else {
                return nil
            }
            if let cutoffDate,
               let modificationDate = values.contentModificationDate,
               modificationDate < cutoffDate {
                return nil
            }
            return url
        }
    }

    static func defaultDeepSeekHarnessRoots(
        homeURL: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> [URL] {
        [
            homeURL.appendingPathComponent(".dsh/sessions", isDirectory: true),
            homeURL.appendingPathComponent(
                "Library/Application Support/@deepseek-ai/dsh-desktop/harness/sessions",
                isDirectory: true
            )
        ]
    }

    private static func parseDeepSeekHarnessFile(_ url: URL) throws -> DeepSeekHarnessFileResult {
        var sessionID = url.deletingLastPathComponent().lastPathComponent
        var sequence = 0
        var candidates: [String: DeepSeekHarnessCandidate] = [:]
        let decodeResult = try DeepSeekHarnessDecoder.decode(fileURL: url) { line in
            sequence += 1
            guard let object = try JSONSerialization.jsonObject(with: line) as? [String: Any] else {
                return
            }
            let eventType = object["type"] as? String ?? ""
            if eventType == "session" || eventType == "session/header" {
                sessionID = nonEmptyString(object["id"] as? String) ?? sessionID
                return
            }
            guard eventType == "assistant/message" || eventType == "assistant/chunk",
                  let data = object["data"] as? [String: Any],
                  let turn = integerValueIfPresent(data["turn"]),
                  let step = integerValueIfPresent(data["step"])
            else {
                return
            }

            let chunk = data["chunk"] as? [String: Any]
            let usage = (data["usage"] as? [String: Any]) ?? (chunk?["usage"] as? [String: Any])
            let isMessage = eventType == "assistant/message"
            let chunkType = data["type"] as? String ?? chunk?["type"] as? String
            guard let usage, isMessage || chunkType == "usage" else {
                return
            }

            let source = ((data["message"] as? [String: Any])?["source"] as? [String: Any])
                ?? ((chunk?["replayState"] as? [String: Any]))
            let model = nonEmptyString(source?["model"] as? String) ?? "unknown"
            let provider = nonEmptyString(source?["provider"] as? String)
            let input = integerValueIfPresent(usage["inputTokens"]) ?? 0
            let output = integerValueIfPresent(usage["outputTokens"]) ?? 0
            let cacheRead = integerValueIfPresent(usage["cacheReadTokens"]) ?? 0
            let cacheWrite = integerValueIfPresent(usage["cacheWriteTokens"]) ?? 0
            let reasoning = integerValueIfPresent(usage["reasoningTokens"]) ?? 0
            guard input >= 0, output >= 0, cacheRead >= 0, cacheWrite >= 0, reasoning >= 0 else {
                return
            }
            let timestampEpoch = epochSeconds(object["time"])
            guard let timestampEpoch,
                  let date = dayString(fromEpoch: timestampEpoch),
                  let timestamp = isoString(fromEpoch: timestampEpoch)
            else {
                return
            }
            let usageCounts = canonicalUsageCounts(
                rawInputTokens: input,
                outputTokens: output,
                cacheCreationInputTokens: cacheWrite,
                cacheReadInputTokens: cacheRead,
                reasoningOutputTokens: reasoning,
                inputIncludesCachedTokens: false
            )
            guard usageCounts.totalTokens > 0 else { return }

            let key = "\(sessionID)|\(turn)|\(step)"
            let candidate = DeepSeekHarnessCandidate(
                key: key,
                date: date,
                timestamp: timestamp,
                timestampEpoch: timestampEpoch,
                model: model,
                usage: usageCounts,
                requestID: key,
                sessionID: sessionID,
                sourcePath: nil,
                lineNumber: sequence,
                dataSource: provider,
                priority: isMessage ? 2 : 1
            )
            if let existing = candidates[key] {
                if candidate.isPreferred(over: existing) {
                    candidates[key] = candidate
                }
            } else {
                candidates[key] = candidate
            }
        }
        return DeepSeekHarnessFileResult(
            records: candidates.values.map(\.record),
            partialTail: decodeResult.partialTail
        )
    }

    private static func mergeDeepSeekHarnessCandidate(
        _ candidate: DeepSeekHarnessCandidate,
        into candidates: inout [String: DeepSeekHarnessCandidate]
    ) {
        guard let key = candidate.key else { return }
        if let existing = candidates[key] {
            if candidate.isPreferred(over: existing) {
                candidates[key] = candidate
            }
        } else {
            candidates[key] = candidate
        }
    }

    private static func integerValueIfPresent(_ value: Any?) -> Int? {
        if let int = value as? Int { return int }
        if let double = value as? Double { return Int(double) }
        if let number = value as? NSNumber { return number.intValue }
        if let string = value as? String { return Int(string) }
        return nil
    }

    static func collectDeepSeekHarnessUsage(
        cache: inout CollectorCache,
        livePaths: inout Set<String>,
        rootURLs: [URL],
        modifiedSince: Date?
    ) -> CollectorResult {
        let urls = rootURLs.flatMap { zstdSessionFiles(under: $0, modifiedSince: modifiedSince) }
        guard !urls.isEmpty else {
            return CollectorResult(
                records: [],
                source: SourceInfo(status: "missing_files", files: 0, records: 0)
            )
        }

        var candidates: [String: DeepSeekHarnessCandidate] = [:]
        var acceptedFiles = 0
        var partialFiles = 0
        var unreadableFiles = 0

        for url in urls {
            livePaths.insert(url.path)
            if let cached = cachedRecords(for: url, tool: "DeepSeek Harness", cache: cache) {
                acceptedFiles += 1
                for record in cached {
                    mergeDeepSeekHarnessCandidate(
                        DeepSeekHarnessCandidate(record: record),
                        into: &candidates
                    )
                }
                continue
            }

            do {
                let beforeMetadata = fileMetadata(for: url)
                let priorRecords = cache.files[url.path]?.records
                let parsed = try parseDeepSeekHarnessFile(url)
                let afterMetadata = fileMetadata(for: url)
                let stable = beforeMetadata.flatMap { before in
                    afterMetadata.map { metadata(before, matches: $0) }
                } ?? false
                acceptedFiles += 1
                if parsed.partialTail || !stable { partialFiles += 1 }
                let recordsToMerge = stable && !parsed.partialTail ? parsed.records : (priorRecords ?? parsed.records)
                for record in recordsToMerge {
                    mergeDeepSeekHarnessCandidate(
                        DeepSeekHarnessCandidate(record: record),
                        into: &candidates
                    )
                }
                if stable && !parsed.partialTail {
                    updateCache(path: url, tool: "DeepSeek Harness", records: parsed.records, cache: &cache)
                }
            } catch {
                unreadableFiles += 1
            }
        }

        let records = candidates.values
            .map(\.record)
            .sorted { lhs, rhs in
                (lhs.timestampEpoch ?? 0) < (rhs.timestampEpoch ?? 0)
            }
        let status: String
        if unreadableFiles > 0 && records.isEmpty {
            status = "unreadable_source"
        } else if partialFiles > 0 {
            status = "partial_tail"
        } else if records.isEmpty {
            status = "missing_valid_rows"
        } else {
            status = "ok"
        }
        return CollectorResult(
            records: records,
            source: SourceInfo(
                status: status,
                files: acceptedFiles,
                records: records.count,
                skippedRecords: unreadableFiles
            )
        )
    }

    static func collectAutoClawUsage(
        rootURLs: [URL]? = nil,
        modifiedSince cutoffDate: Date?
    ) -> CollectorResult {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let roots = rootURLs ?? [
            home.appendingPathComponent(".openclaw-autoclaw/agents", isDirectory: true)
        ]
        let sessionRoots = roots.flatMap { root -> [URL] in
            guard FileManager.default.fileExists(atPath: root.path),
                  let contents = try? FileManager.default.contentsOfDirectory(
                    at: root, includingPropertiesForKeys: [.isDirectoryKey]
                  )
            else { return [] }
            return contents.filter { agent in
                (try? agent.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            }.map { $0.appendingPathComponent("sessions", isDirectory: true) }
        }
        let discoveredRoots = sessionRoots.filter { FileManager.default.fileExists(atPath: $0.path) }
        let files = discoveredRoots.flatMap { jsonlFiles(under: $0, modifiedSince: cutoffDate) }
        var records: [UsageRecord] = []

        for file in files {
            var lineNumber = 0
            try? forEachLine(in: file, matchingAny: ["\"usage\""]) { line in
                lineNumber += 1
                guard let data = line.data(using: .utf8),
                      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let message = object["message"] as? [String: Any],
                      let usageDict = message["usage"] as? [String: Any],
                      let day = dayString(fromISO: (object["timestamp"] as? String) ?? ""),
                      !day.isEmpty
                else {
                    return
                }

                let input = firstIntegerValue(
                    in: usageDict,
                    keys: ["input"]
                )
                let output = firstIntegerValue(
                    in: usageDict,
                    keys: ["output"]
                )
                let cacheRead = firstIntegerValue(
                    in: usageDict,
                    keys: ["cacheRead"]
                )
                let cacheWrite = firstIntegerValue(
                    in: usageDict,
                    keys: ["cacheWrite"]
                )
                let reasoning = firstIntegerValue(
                    in: usageDict,
                    keys: ["reasoningTokens"]
                )
                // OpenClaw records input including cached tokens; total is explicit.
                let counts = canonicalUsageCounts(
                    rawInputTokens: input,
                    outputTokens: output,
                    cacheCreationInputTokens: cacheWrite,
                    cacheReadInputTokens: cacheRead,
                    reasoningOutputTokens: reasoning,
                    inputIncludesCachedTokens: true,
                    explicitTotalTokens: firstIntegerValue(in: usageDict, keys: ["totalTokens"]),
                    explicitTotalIsAuthoritative: true
                )
                guard counts.totalTokens > 0 else { return }

                let timestamp = isoString(fromEpoch: object["timestamp"])
                    ?? (object["timestamp"] as? String)
                let epoch = epochSeconds(object["timestamp"])
                let recordType = object["type"] as? String
                records.append(UsageRecord(
                    date: day,
                    timestamp: timestamp,
                    timestampEpoch: epoch,
                    tool: "AutoClaw",
                    model: modelKey(message["model"] as? String),
                    usage: counts,
                    source: .autoclaw,
                    requestID: nonEmptyString(message["responseId"] as? String),
                    sessionID: nonEmptyString(object["id"] as? String),
                    sourcePath: file.path,
                    lineNumber: lineNumber,
                    modelRequestCount: 1,
                    toolCallCount: recordType == "function_call" ? 1 : 0
                ))
            }
        }

        let status: String
        if roots.allSatisfy({ !FileManager.default.fileExists(atPath: $0.path) }) {
            status = "missing"
        } else if files.isEmpty {
            status = "discovered_no_usage"
        } else if records.isEmpty {
            status = "missing_valid_rows"
        } else {
            status = "ok"
        }
        return CollectorResult(
            records: records,
            source: SourceInfo(
                status: status,
                files: files.count,
                records: records.count
            )
        )
    }
}

fileprivate struct DeepSeekHarnessFileResult {
    var records: [UsageRecord]
    var partialTail: Bool
}

fileprivate struct DeepSeekHarnessCandidate {
    var key: String?
    var date: String
    var timestamp: String?
    var timestampEpoch: TimeInterval?
    var model: String
    var usage: TokenUsageCounts
    var requestID: String?
    var sessionID: String?
    var sourcePath: String?
    var lineNumber: Int?
    var dataSource: String?
    var priority: Int

    init(
        key: String,
        date: String,
        timestamp: String?,
        timestampEpoch: TimeInterval?,
        model: String,
        usage: TokenUsageCounts,
        requestID: String?,
        sessionID: String?,
        sourcePath: String?,
        lineNumber: Int?,
        dataSource: String?,
        priority: Int
    ) {
        self.key = key
        self.date = date
        self.timestamp = timestamp
        self.timestampEpoch = timestampEpoch
        self.model = model
        self.usage = usage
        self.requestID = requestID
        self.sessionID = sessionID
        self.sourcePath = sourcePath
        self.lineNumber = lineNumber
        self.dataSource = dataSource
        self.priority = priority
    }

    init(record: UsageRecord) {
        self.key = record.requestID
        self.date = record.date
        self.timestamp = record.timestamp
        self.timestampEpoch = record.timestampEpoch
        self.model = record.model
        self.usage = record.usage
        self.requestID = record.requestID
        self.sessionID = record.sessionID
        self.sourcePath = record.sourcePath
        self.lineNumber = record.lineNumber
        self.dataSource = record.dataSource
        self.priority = 2
    }

    var record: UsageRecord {
        UsageRecord(
            date: date,
            timestamp: timestamp,
            timestampEpoch: timestampEpoch,
            tool: "DeepSeek Harness",
            model: model,
            usage: usage,
            source: .deepSeekHarness,
            requestID: requestID,
            sessionID: sessionID,
            sourcePath: sourcePath,
            lineNumber: lineNumber,
            dataSource: dataSource
        )
    }

    func isPreferred(over other: DeepSeekHarnessCandidate) -> Bool {
        if priority != other.priority { return priority > other.priority }
        if (timestampEpoch ?? 0) != (other.timestampEpoch ?? 0) {
            return (timestampEpoch ?? 0) > (other.timestampEpoch ?? 0)
        }
        return (lineNumber ?? 0) > (other.lineNumber ?? 0)
    }
}
