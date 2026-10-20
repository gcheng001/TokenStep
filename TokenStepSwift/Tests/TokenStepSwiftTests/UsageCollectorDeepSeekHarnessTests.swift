import Foundation
import XCTest
@testable import TokenStepSwift

final class UsageCollectorDeepSeekHarnessTests: XCTestCase {
    func testHarnessUsageReadsCumulativeSessionTotalsOnce() throws {
        let root = try makeRoot(prefix: "TokenStepHarnessDesktop")
        let sessionFile = root.appendingPathComponent("cf782029-session.json")
        try writeSession(
            to: sessionFile,
            uncachedInput: 3_000,
            output: 500,
            cacheRead: 6_000,
            cacheWrite: 500,
            lastPromptAt: 1_790_918_822_985,
            model: "glm-5.3",
            provider: "agent2api"
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let snapshot = UsageCollector.collectUsageSnapshotForTests(
            deepSeekHarnessRootURLs: [root],
            includeExperimentalAgentSources: true
        )

        let source = try XCTUnwrap(snapshot.sources["DeepSeek Harness"])
        XCTAssertEqual(source.status, "ok")
        XCTAssertEqual(source.records, 1)
        XCTAssertEqual(source.files, 1)
        XCTAssertEqual(snapshot.totals.tokens, 10_000)
        let harnessModels = snapshot.models.filter { $0.tool == "DeepSeek Harness" }
        XCTAssertEqual(harnessModels.map(\.model), ["glm-5.3"])
        XCTAssertEqual(harnessModels.reduce(0) { $0 + $1.tokens }, 10_000)
    }

    func testHarnessCollectorAggregatesSessionsAndSkipsEmptyTotals() throws {
        let root = try makeRoot(prefix: "TokenStepHarnessMulti")
        try writeSession(
            to: root.appendingPathComponent("session-a.json"),
            uncachedInput: 100,
            output: 20,
            cacheRead: 80,
            cacheWrite: 0,
            lastPromptAt: 1_790_918_822_985,
            model: "glm-5.3",
            provider: "agent2api"
        )
        try writeSession(
            to: root.appendingPathComponent("session-b.json"),
            uncachedInput: 200,
            output: 40,
            cacheRead: 160,
            cacheWrite: 0,
            lastPromptAt: 1_790_918_822_985,
            model: "deepseek-v4.1-flash",
            provider: "agent2api"
        )
        try writeSession(
            to: root.appendingPathComponent("session-empty.json"),
            uncachedInput: 0,
            output: 0,
            cacheRead: 0,
            cacheWrite: 0,
            lastPromptAt: 1_790_918_822_985,
            model: "glm-5.3",
            provider: "agent2api"
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let snapshot = UsageCollector.collectUsageSnapshotForTests(
            deepSeekHarnessRootURLs: [root],
            includeExperimentalAgentSources: true
        )

        let source = try XCTUnwrap(snapshot.sources["DeepSeek Harness"])
        XCTAssertEqual(source.status, "ok")
        XCTAssertEqual(source.records, 2)
        XCTAssertEqual(snapshot.totals.tokens, 600)
    }

    func testHarnessCollectorIgnoresUndecodableSessionDocuments() throws {
        let root = try makeRoot(prefix: "TokenStepHarnessMalformed")
        let file = root.appendingPathComponent("session-bad.json")
        try Data("{\"not\":\"a session\"}".utf8).write(to: file)
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let snapshot = UsageCollector.collectUsageSnapshotForTests(
            deepSeekHarnessRootURLs: [root],
            includeExperimentalAgentSources: true
        )

        XCTAssertEqual(snapshot.sources["DeepSeek Harness"]?.status, "unreadable_source")
        XCTAssertEqual(snapshot.sources["DeepSeek Harness"]?.records, 0)
        XCTAssertEqual(snapshot.totals.tokens, 0)
    }

    func testCollectionStateTracksHarnessSessionFiles() throws {
        let root = try makeRoot(prefix: "TokenStepHarnessState")
        let file = root.appendingPathComponent("session-state.json")
        try writeSession(
            to: file,
            uncachedInput: 10,
            output: 5,
            cacheRead: 0,
            cacheWrite: 0,
            lastPromptAt: 1_790_918_822_985,
            model: "glm-5.3",
            provider: "agent2api"
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: root)
        }

        let state = UsageCollector.collectionState(
            historyDays: 180,
            includeExperimentalAgentSources: true,
            deepSeekHarnessRootURLs: [root],
            homeURL: FileManager.default.temporaryDirectory
        )

        XCTAssertTrue(state.files.contains { $0.path == file.path })
    }

    private func makeRoot(prefix: String) throws -> URL {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func writeSession(
        to url: URL,
        uncachedInput: Int,
        output: Int,
        cacheRead: Int,
        cacheWrite: Int,
        lastPromptAt: Int,
        model: String,
        provider: String
    ) throws {
        let payload: [String: Any] = [
            "version": 1,
            "record": [
                "identity": [
                    "formatVersion": 4,
                    "createdAt": lastPromptAt,
                    "cwd": "/tmp/workspace",
                    "isSeeded": false,
                    "inheritedEventCount": 0
                ],
                "rows": [
                    "tokenUsage": [
                        "ver": 2,
                        "seq": 1,
                        "val": [
                            "totals": [
                                "uncachedInputTokens": uncachedInput,
                                "outputTokens": output,
                                "cacheReadTokens": cacheRead,
                                "cacheWriteTokens": cacheWrite
                            ],
                            "last": NSNull()
                        ]
                    ],
                    "sessionListMetadata": [
                        "ver": 1,
                        "seq": 1,
                        "val": ["blank": false, "lastPromptAt": lastPromptAt]
                    ],
                    "modelSelection": [
                        "ver": 2,
                        "seq": 1,
                        "val": ["lastUsed": ["provider": provider, "model": model], "pending": NSNull()]
                    ]
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: payload)
        try data.write(to: url)
    }
}
