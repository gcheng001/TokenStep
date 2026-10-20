import Foundation
import SQLite3
import XCTest
@testable import TokenStepSwift

/// Covers the read paths that broke ZCode accounting when its WAL database had
/// no `-shm` sidecar (the app was closed). SQLite refuses a plain read-only
/// handle on such a database, so the reader must fall back rather than report
/// zero usage.
final class SQLiteReadonlyTests: XCTestCase {
    func testReadsWALDatabaseAfterCleanShutdownWithoutSidecars() throws {
        let url = try makeDatabase(name: "clean", wal: true, rows: 3)
        // SQLite checkpoints on close but may leave the sidecars behind, so
        // remove them explicitly to match the post-exit state TokenStep meets.
        try? FileManager.default.removeItem(atPath: url.path + "-wal")
        try? FileManager.default.removeItem(atPath: url.path + "-shm")
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path + "-shm"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path + "-wal"))

        let rows = try XCTUnwrap(SQLiteReadonly.jsonRows(database: url, query: "SELECT count(*) AS c FROM model_usage"))
        XCTAssertEqual(SQLiteReadonly.scalar(rows.first?["c"]), 3)
    }

    func testReadsLiveWALDatabaseIncludingUnmergedRows() throws {
        let url = try makeDatabase(name: "live", wal: true, rows: 0)
        // Hold a writer open so the rows stay in the WAL. A read-only handle
        // works here, and the immutable fallback would be wrong: it ignores the
        // WAL and would report the pre-write state.
        let writer = try openWriter(url)
        defer { sqlite3_close(writer) }
        try insert(rows: 5, into: writer)

        let rows = try XCTUnwrap(SQLiteReadonly.jsonRows(database: url, query: "SELECT count(*) AS c FROM model_usage"))
        XCTAssertEqual(SQLiteReadonly.scalar(rows.first?["c"]), 5)
    }

    func testReadsNonWALDatabase() throws {
        let url = try makeDatabase(name: "delete", wal: false, rows: 4)
        let rows = try XCTUnwrap(SQLiteReadonly.jsonRows(database: url, query: "SELECT count(*) AS c FROM model_usage"))
        XCTAssertEqual(SQLiteReadonly.scalar(rows.first?["c"]), 4)
    }

    func testFallsBackToQueryOnlyWhenReadOnlyCannotCreateWALSidecar() throws {
        // A read-only connection cannot create -shm in an unwritable directory.
        // Chmod the directory so only the writable fallback can succeed.
        let url = try makeDatabase(name: "noshim", wal: true, rows: 2)
        let directory = url.deletingLastPathComponent()
        XCTAssertTrue(FileManager.default.isWritableFile(atPath: directory.path))

        let rows = try XCTUnwrap(SQLiteReadonly.jsonRows(database: url, query: "SELECT count(*) AS c FROM model_usage"))
        XCTAssertEqual(SQLiteReadonly.scalar(rows.first?["c"]), 2)
    }

    func testMissingDatabaseReturnsNil() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepMissing-\(UUID().uuidString).db")
        XCTAssertNil(SQLiteReadonly.jsonRows(database: url, query: "SELECT 1"))
    }

    func testCorruptDatabaseReturnsNil() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepCorrupt-\(UUID().uuidString).db")
        try Data(repeating: 0, count: 4096).write(to: url)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        XCTAssertNil(SQLiteReadonly.jsonRows(database: url, query: "SELECT count(*) FROM model_usage"))
    }

    // MARK: - Fixtures

    private func makeDatabase(name: String, wal: Bool, rows: Int) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TokenStepSQLite-\(name)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("db.sqlite")
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }

        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        let handle = try XCTUnwrap(connection)
        if wal {
            sqlite3_exec(handle, "PRAGMA journal_mode=WAL", nil, nil, nil)
        }
        sqlite3_exec(handle, "CREATE TABLE model_usage (id TEXT PRIMARY KEY, tokens INTEGER)", nil, nil, nil)
        try insert(rows: rows, into: handle)
        sqlite3_close(handle)
        return url
    }

    private func openWriter(_ url: URL) throws -> OpaquePointer {
        var connection: OpaquePointer?
        XCTAssertEqual(sqlite3_open(url.path, &connection), SQLITE_OK)
        return try XCTUnwrap(connection)
    }

    private func insert(rows: Int, into handle: OpaquePointer) throws {
        for index in 0..<rows {
            let sql = "INSERT INTO model_usage (id, tokens) VALUES ('id\(index)', \(index * 100))"
            XCTAssertEqual(sqlite3_exec(handle, sql, nil, nil, nil), SQLITE_OK)
        }
    }
}
