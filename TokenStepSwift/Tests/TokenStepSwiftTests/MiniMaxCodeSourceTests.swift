import Foundation
import SQLite3
import XCTest
@testable import TokenStepSwift

final class MiniMaxCodeSourceTests: XCTestCase {
    func testCollectsIncrementalRowsFromRuntimeState() throws {
        let url = try makeRuntimeState(rows: [
            (1_792_677_119_994, 1_000, 200, 0, 5_000, 0),
            (1_792_677_200_000, 2_000, 300, 0, 6_000, 0),
        ])

        let result = UsageCollector.collectMiniMaxCodeUsage(databaseURL: url)

        XCTAssertEqual(result.source.status, "ok")
        XCTAssertEqual(result.source.records, 2)
        XCTAssertEqual(result.records.count, 2)
        XCTAssertTrue(result.records.allSatisfy { $0.tool == "MiniMax Code" })
        // Deltas add up; cache reads are a separate bucket.
        XCTAssertEqual(result.records.reduce(0) { $0 + $1.usage.totalTokens }, 14_500)
    }

    func testReadsWhileRuntimeDatabaseIsOpen() throws {
        let url = try makeRuntimeState(rows: [])
        let writer = try open(url)
        defer { sqlite3_close(writer) }
        try insert(row: (1_792_677_300_000, 500, 100, 0, 1_000, 0), into: writer)

        let result = UsageCollector.collectMiniMaxCodeUsage(databaseURL: url)

        XCTAssertEqual(result.source.status, "ok")
        XCTAssertEqual(result.records.count, 1)
        XCTAssertEqual(result.records.first?.usage.totalTokens, 1_600)
    }

    func testReportsMissingDatabase() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepMiniMaxMissing-\(UUID().uuidString).sqlite")
        XCTAssertEqual(UsageCollector.collectMiniMaxCodeUsage(databaseURL: url).source.status, "missing_db")
    }

    func testReportsMissingTable() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepMiniMaxNoTable-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("runtime-state.sqlite")
        let connection = try open(url)
        sqlite3_exec(connection, "CREATE TABLE unrelated (id INTEGER)", nil, nil, nil)
        sqlite3_close(connection)

        XCTAssertEqual(UsageCollector.collectMiniMaxCodeUsage(databaseURL: url).source.status, "missing_table")
    }

    // MARK: - Fixtures

    private func makeRuntimeState(rows: [(Int, Int, Int, Int, Int, Int)]) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepMiniMax-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("runtime-state.sqlite")

        let connection = try open(url)
        defer { sqlite3_close(connection) }
        sqlite3_exec(connection, "PRAGMA journal_mode=WAL", nil, nil, nil)
        let schema = """
        CREATE TABLE local_runtime_token_usage (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id TEXT NOT NULL,
            agent_name TEXT NOT NULL,
            framework_type TEXT NOT NULL,
            turn_id TEXT,
            model TEXT,
            ts INTEGER NOT NULL,
            input_tokens INTEGER NOT NULL,
            output_tokens INTEGER NOT NULL,
            reasoning_tokens INTEGER NOT NULL,
            cache_read_tokens INTEGER NOT NULL,
            cache_write_tokens INTEGER NOT NULL,
            cost_usd REAL,
            raw TEXT
        )
        """
        XCTAssertEqual(sqlite3_exec(connection, schema, nil, nil, nil), SQLITE_OK)
        for row in rows { try insert(row: row, into: connection) }
        return url
    }

    private func insert(row: (Int, Int, Int, Int, Int, Int), into handle: OpaquePointer) throws {
        let (ts, input, output, reasoning, cacheRead, cacheWrite) = row
        let sql = """
        INSERT INTO local_runtime_token_usage
            (session_id, agent_name, framework_type, turn_id, model, ts,
             input_tokens, output_tokens, reasoning_tokens, cache_read_tokens, cache_write_tokens, cost_usd)
        VALUES ('mvs_test', 'mavis', 'pi-agent', 'turn_1', 'MiniMax-M3', \(ts),
                \(input), \(output), \(reasoning), \(cacheRead), \(cacheWrite), 0.0)
        """
        XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, nil), SQLITE_OK)
    }

    private func open(_ url: URL) throws -> OpaquePointer {
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        return try XCTUnwrap(connection)
    }
}
