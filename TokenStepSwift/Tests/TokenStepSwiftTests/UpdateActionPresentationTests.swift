import Foundation
import XCTest
@testable import TokenStepSwift

final class UpdateActionPresentationTests: XCTestCase {
    func testCheckingTakesPrecedenceOverPreviouslyAvailableUpdate() {
        XCTAssertEqual(
            UpdateActionVisualState.resolve(
                isCheckingForUpdates: true,
                availableUpdate: makeUpdate(version: "0.2.6"),
                phase: .available(makeUpdate(version: "0.2.6"), checkedAt: .distantPast)
            ),
            .checking
        )
    }

    func testVisibleUpdateTakesPrecedenceOverTransientPhase() {
        XCTAssertEqual(
            UpdateActionVisualState.resolve(
                isCheckingForUpdates: false,
                availableUpdate: makeUpdate(version: "0.2.6"),
                phase: .upToDate(checkedAt: .distantPast)
            ),
            .available(version: "0.2.6")
        )
    }

    func testEveryUpdatePhaseMapsToSharedButtonState() {
        let checkedAt = Date(timeIntervalSince1970: 1_787_628_600)
        let update = makeUpdate(version: "0.2.6")

        XCTAssertEqual(resolve(.idle), .idle)
        XCTAssertEqual(resolve(.checking), .checking)
        XCTAssertEqual(resolve(.upToDate(checkedAt: checkedAt)), .upToDate(checkedAt: checkedAt))
        XCTAssertEqual(resolve(.available(update, checkedAt: checkedAt)), .available(version: "0.2.6"))
        XCTAssertEqual(resolve(.failed(checkedAt: checkedAt, message: "offline")), .failed)
    }

    func testAvailableStateExposesBadgeAndCheckingStateDisablesInteraction() {
        XCTAssertTrue(UpdateActionVisualState.available(version: "0.2.6").isAvailable)
        XCTAssertFalse(UpdateActionVisualState.available(version: "0.2.6").isChecking)
        XCTAssertTrue(UpdateActionVisualState.checking.isChecking)
        XCTAssertFalse(UpdateActionVisualState.checking.isAvailable)
    }

    private func resolve(_ phase: UpdateCheckPhase) -> UpdateActionVisualState {
        UpdateActionVisualState.resolve(
            isCheckingForUpdates: false,
            availableUpdate: nil,
            phase: phase
        )
    }

    private func makeUpdate(version: String) -> AvailableUpdate {
        AvailableUpdate(
            version: version,
            tagName: "v\(version)",
            title: "TokenStep \(version)",
            notes: "",
            pageURL: URL(string: "https://example.com/release")!,
            assetURL: URL(string: "https://example.com/app.dmg")!,
            assetName: "TokenStep.dmg",
            assetSize: 1
        )
    }
}
