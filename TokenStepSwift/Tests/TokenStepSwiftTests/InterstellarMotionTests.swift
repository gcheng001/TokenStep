import XCTest
@testable import TokenStepSwift

final class InterstellarMotionTests: XCTestCase {
    func testMotionRunsAtLowCostOnlyOnVisibleInteractiveSurfaces() {
        XCTAssertEqual(InterstellarMotionPolicy.preferredFramesPerSecond, 24)
        XCTAssertTrue(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: false,
                isScreenshotRendering: false,
                isControlActive: true
            )
        )
        XCTAssertFalse(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: true,
                isScreenshotRendering: false,
                isControlActive: true
            )
        )
        XCTAssertFalse(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: false,
                isScreenshotRendering: true,
                isControlActive: true
            )
        )
        XCTAssertFalse(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: false,
                isScreenshotRendering: false,
                isControlActive: false
            )
        )
    }
}
