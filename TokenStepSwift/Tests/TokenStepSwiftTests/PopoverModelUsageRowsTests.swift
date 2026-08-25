import XCTest
@testable import TokenStepSwift

final class PopoverModelUsageRowsTests: XCTestCase {
    func testOneToThreeModelsRemainIndividualAndSorted() throws {
        let usage = makeUsage(
            models: ["small": 100, "large": 600, "medium": 300],
            totalTokens: 1_200
        )

        let rows = try rows(from: usage)

        XCTAssertEqual(rows.map(\.kind), [.model("large"), .model("medium"), .model("small")])
        XCTAssertEqual(rows.map(\.tokens), [600, 300, 100])
        XCTAssertEqual(rows.map(\.percent), [50, 25, 100.0 / 12.0])
    }

    func testMoreThanThreeModelsUseTopThreeAndAggregateEveryRemainingToken() throws {
        let usage = makeUsage(
            models: ["a": 500, "b": 300, "c": 100, "d": 60, "e": 30, "f": 10],
            totalTokens: 1_000
        )

        let rows = try rows(from: usage)

        XCTAssertEqual(rows.map(\.kind), [.model("a"), .model("b"), .model("c"), .other])
        XCTAssertEqual(rows.map(\.tokens), [500, 300, 100, 100])
        XCTAssertEqual(rows.last?.percent, 10)
        XCTAssertEqual(rows.count, PopoverModelUsageRows.maximumVisibleRows)
    }

    func testOtherIncludesNegligibleRowsHiddenByDashboard() throws {
        let usage = makeUsage(
            models: ["primary": 9_990, "b": 2, "c": 2, "d": 2, "e": 2, "f": 2],
            totalTokens: 10_000
        )

        XCTAssertLessThan(TodayModelUsageRows.make(from: usage).count, usage.models.count)
        let rows = try rows(from: usage)
        XCTAssertEqual(rows.map(\.kind), [.model("primary"), .model("b"), .model("c"), .other])
        XCTAssertEqual(rows.last?.tokens, 6)
        XCTAssertEqual(rows.reduce(0) { $0 + $1.tokens }, 10_000)
    }

    func testZeroTotalHidesSectionAndMissingDetailsWait() {
        XCTAssertEqual(
            PopoverModelUsageRows.state(from: makeUsage(models: ["gpt": 10], totalTokens: 0)),
            .hidden
        )
        XCTAssertEqual(
            PopoverModelUsageRows.state(from: makeUsage(models: [:], totalTokens: 100)),
            .waiting
        )
    }

    func testRealOtherModelDoesNotCollideWithAggregateIdentity() throws {
        let usage = makeUsage(
            models: ["other": 400, "a": 300, "b": 200, "c": 80, "d": 20],
            totalTokens: 1_000
        )
        let rows = try rows(from: usage)
        XCTAssertEqual(Set(rows.map(\.id)).count, rows.count)
        XCTAssertTrue(rows.contains { $0.kind == .model("other") })
        XCTAssertTrue(rows.contains { $0.kind == .other })
    }

    func testMismatchFlagAndPercentClampArePreserved() throws {
        let usage = makeUsage(models: ["unexpected": 150], totalTokens: 100)
        guard case let .rows(rows, mismatch) = PopoverModelUsageRows.state(from: usage) else {
            return XCTFail("Expected rows")
        }
        XCTAssertTrue(mismatch)
        XCTAssertEqual(rows.first?.percent, 100)
    }

    private func rows(from usage: DailyUsage) throws -> [PopoverModelUsageRow] {
        guard case let .rows(rows, _) = PopoverModelUsageRows.state(from: usage) else {
            throw NSError(domain: "PopoverModelUsageRowsTests", code: 1)
        }
        return rows
    }

    private func makeUsage(models: [String: Int], totalTokens: Int) -> DailyUsage {
        DailyUsage(
            date: "2026-08-25",
            tools: totalTokens > 0 ? ["Codex": totalTokens] : [:],
            models: models,
            modelCosts: [:],
            totalTokens: totalTokens,
            cost: 0
        )
    }
}
