import Foundation
import SQLite3
import XCTest
@testable import TokenStepSwift

/// End-to-end coverage for the ZCode source: the collector must keep reading
/// after the owning app exits and removes the WAL sidecars, and a failing read
/// must not be mistaken for genuinely zero usage.
final class ZCodeSourceResilienceTests: XCTestCase {
    func testCollectsZCodeRowsAfterWALSidecarsAreRemoved() throws {
        let url = try makeZCodeDatabase(rows: 7)
        // TokenStep met this state whenever ZCode was quit: only the main
        // database file remains and a read-only handle cannot attach the WAL.
        try? FileManager.default.removeItem(atPath: url.path + "-wal")
        try? FileManager.default.removeItem(atPath: url.path + "-shm")

        let result = UsageCollector.collectZCodeUsage(databaseURL: url)

        XCTAssertEqual(result.source.status, "ok")
        XCTAssertEqual(result.source.records, 7)
        XCTAssertEqual(result.records.count, 7)
        XCTAssertTrue(result.records.allSatisfy { $0.tool == "ZCode" })
        XCTAssertTrue(result.records.allSatisfy { $0.usage.totalTokens > 0 })
    }

    func testCollectsZCodeRowsWhileDatabaseIsOpen() throws {
        let url = try makeZCodeDatabase(rows: 4)
        // Keep the writer alive so rows stay in the WAL; the collector must see
        // them, which rules out an immutable-only read path.
        let writer = try openConnection(url)
        defer { sqlite3_close(writer) }

        let result = UsageCollector.collectZCodeUsage(databaseURL: url)

        XCTAssertEqual(result.source.status, "ok")
        XCTAssertEqual(result.records.count, 4)
    }

    func testReportsUnreadableForCorruptDatabase() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepZCodeCorrupt-\(UUID().uuidString).db")
        try Data(repeating: 0, count: 4096).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }

        let result = UsageCollector.collectZCodeUsage(databaseURL: url)

        // Any failure status is fine as long as it is not reported as success
        // with zero rows; the caller keeps the previous snapshot on failure.
        XCTAssertNotEqual(result.source.status, "ok")
        XCTAssertEqual(result.records.count, 0)
    }

    func testReportsMissingDatabase() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepZCodeMissing-\(UUID().uuidString).db")
        let result = UsageCollector.collectZCodeUsage(databaseURL: url)
        XCTAssertEqual(result.source.status, "missing_db")
    }

    // MARK: - Fixtures

    private func makeZCodeDatabase(rows: Int) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepZCode-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("db.sqlite")
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }

        let connection = try openConnection(url)
        defer { sqlite3_close(connection) }
        sqlite3_exec(connection, "PRAGMA journal_mode=WAL", nil, nil, nil)
        let schema = """
        CREATE TABLE model_usage (
            id TEXT PRIMARY KEY,
            session_id TEXT,
            started_at INTEGER,
            status TEXT,
            model_id TEXT,
            input_tokens INTEGER,
            output_tokens INTEGER,
            reasoning_tokens INTEGER,
            cache_creation_input_tokens INTEGER,
            cache_read_input_tokens INTEGER,
            computed_total_tokens INTEGER,
            tool_call_count INTEGER,
            provider_total_tokens INTEGER
        )
        """
        XCTAssertEqual(sqlite3_exec(connection, schema, nil, nil, nil), SQLITE_OK)

        let started = 1_792_476_976_698
        for index in 0..<rows {
            let sql = """
            INSERT INTO model_usage VALUES (
                'id\(index)', 'session-1', \(started + index * 1_000), 'completed', 'glm-5.3',
                1_000, 500, 0, 0, 200, 1_700, 1, 1_700
            )
            """
            XCTAssertEqual(sqlite3_exec(connection, sql, nil, nil, nil), SQLITE_OK)
        }
        return url
    }

    private func openConnection(_ url: URL) throws -> OpaquePointer {
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        return try XCTUnwrap(connection)
    }
}
