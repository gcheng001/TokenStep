import Foundation
import XCTest
@testable import TokenStepSwift

/// Guards the "never overwrite real usage with silence" rule: when a source
/// that reported data last cycle now fails to read, the snapshot write must be
/// blocked so the previous numbers survive. A source that was already empty, or
/// one the user disabled, is not a regression.
final class SourceReadRegressionTests: XCTestCase {
    func testHealthySourceBecomingUnreadableBlocksTheWrite() {
        let previous = snapshot(sources: ["ZCode": ("ok", 3_221_000)])
        let collected = snapshot(sources: ["ZCode": ("unreadable_db", 0)])

        let regression = DataService.sourceReadRegression(
            collected: collected,
            previous: previous,
            settings: .defaults
        )

        XCTAssertEqual(regression, "ZCode")
    }

    func testQueryFailureOnPreviouslyPopulatedSourceBlocksTheWrite() {
        let previous = snapshot(sources: ["Hermes Agent": ("ok", 900)])
        let collected = snapshot(sources: ["Hermes Agent": ("query_failed", 0)])

        XCTAssertEqual(
            DataService.sourceReadRegression(
                collected: collected,
                previous: previous,
                settings: .defaults
            ),
            "Hermes Agent"
        )
    }

    func testSourceThatWasAlreadyEmptyIsNotARegression() {
        let previous = snapshot(sources: ["ZCode": ("ok", 0)])
        let collected = snapshot(sources: ["ZCode": ("unreadable_db", 0)])

        XCTAssertNil(
            DataService.sourceReadRegression(
                collected: collected,
                previous: previous,
                settings: .defaults
            )
        )
    }

    func testGenuinelyMissingDatabaseIsNotARegression() {
        let previous = snapshot(sources: ["ZCode": ("ok", 500)])
        // missing_db means the file is gone, which is a real state change, not
        // a transient read failure.
        let collected = snapshot(sources: ["ZCode": ("missing_db", 0)])

        XCTAssertNil(
            DataService.sourceReadRegression(
                collected: collected,
                previous: previous,
                settings: .defaults
            )
        )
    }

    func testDisabledSourceIsNotARegression() {
        var settings = TokenStepSettings.defaults
        settings.showDeepSeekHarnessSource = false
        let previous = snapshot(sources: ["DeepSeek Harness": ("ok", 1_000)])
        // A switched-off source is collected as "disabled", which is not a read
        // failure, so it must not freeze the whole snapshot.
        let collected = snapshot(sources: ["DeepSeek Harness": ("disabled", 0)])

        XCTAssertNil(
            DataService.sourceReadRegression(
                collected: collected,
                previous: previous,
                settings: settings
            )
        )
    }

    func testHealthyCollectionIsNotARegression() {
        let previous = snapshot(sources: ["ZCode": ("ok", 1_000)])
        let collected = snapshot(sources: ["ZCode": ("ok", 1_200)])

        XCTAssertNil(
            DataService.sourceReadRegression(
                collected: collected,
                previous: previous,
                settings: .defaults
            )
        )
    }

    func testNoPreviousSnapshotIsNotARegression() {
        let collected = snapshot(sources: ["ZCode": ("unreadable_db", 0)])
        XCTAssertNil(
            DataService.sourceReadRegression(
                collected: collected,
                previous: nil,
                settings: .defaults
            )
        )
    }

    // MARK: - Helpers

    private func snapshot(sources: [String: (status: String, records: Int)]) -> UsageSnapshot {
        var infos: [String: SourceInfo] = [:]
        for (name, value) in sources {
            infos[name] = SourceInfo(status: value.status, files: 1, records: value.records)
        }
        return UsageSnapshot(
            generatedAt: "2026-10-20T06:00:00Z",
            timezone: "Asia/Shanghai",
            totals: UsageTotals(tokens: 0, cost: 0, activeDays: 0),
            daily: [],
            rhythms: [],
            agentWork: [],
            tools: [],
            models: [],
            sources: infos
        )
    }
}
