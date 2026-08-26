import XCTest
@testable import TokenStepSwift

final class InterstellarMotionTests: XCTestCase {
    func testMotionRunsAtLowCostOnlyOnVisibleInteractiveSurfaces() {
        XCTAssertEqual(InterstellarMotionPolicy.preferredFramesPerSecond, 24)
        XCTAssertTrue(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: false,
                isScreenshotRendering: false,
                isSurfaceVisible: true
            )
        )
        XCTAssertFalse(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: true,
                isScreenshotRendering: false,
                isSurfaceVisible: true
            )
        )
        XCTAssertFalse(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: false,
                isScreenshotRendering: true,
                isSurfaceVisible: true
            )
        )
        XCTAssertFalse(
            InterstellarMotionPolicy.shouldAnimate(
                reduceMotion: false,
                isScreenshotRendering: false,
                isSurfaceVisible: false
            )
        )
    }

    func testMotionModesAndLowPowerFrameCaps() {
        XCTAssertEqual(InterstellarMotionMode.quiet.preferredFramesPerSecond, 12)
        XCTAssertEqual(InterstellarMotionMode.orbit.preferredFramesPerSecond, 24)
        XCTAssertEqual(InterstellarMotionMode.gravityTide.preferredFramesPerSecond, 24)
        XCTAssertEqual(
            InterstellarMotionPolicy.framesPerSecond(mode: .gravityTide, lowPowerMode: false),
            24
        )
        XCTAssertEqual(
            InterstellarMotionPolicy.framesPerSecond(mode: .gravityTide, lowPowerMode: true),
            12
        )
    }

    func testMotionSignatureDifferentiatesModes() {
        XCTAssertFalse(InterstellarMotionMode.quiet.showsHotspot)
        XCTAssertTrue(InterstellarMotionMode.orbit.showsHotspot)
        XCTAssertTrue(InterstellarMotionMode.gravityTide.showsHotspot)

        XCTAssertFalse(InterstellarMotionMode.quiet.usesApproach)
        XCTAssertFalse(InterstellarMotionMode.orbit.usesApproach)
        XCTAssertTrue(InterstellarMotionMode.gravityTide.usesApproach)

        XCTAssertEqual(InterstellarMotionMode.quiet.filamentCount, 0)
        XCTAssertEqual(InterstellarMotionMode.quiet.starCount, 0)
        XCTAssertGreaterThan(InterstellarMotionMode.orbit.filamentCount, 0)
        XCTAssertGreaterThan(InterstellarMotionMode.gravityTide.starCount, 0)
    }

    func testMotionSamplePhasesAreBoundedAndPeriodic() {
        let first = InterstellarMotionSample.sample(at: 12.5)
        let repeatedPrimary = InterstellarMotionSample.sample(at: 12.5 + 9)
        let repeatedHotspot = InterstellarMotionSample.sample(
            at: 12.5 + InterstellarMotionSample.hotspotPeriod
        )

        for phase in [
            first.primaryPhase,
            first.secondaryPhase,
            first.starPhase,
            first.breath,
            first.hotspotPhase
        ] {
            XCTAssertGreaterThanOrEqual(phase, 0)
            XCTAssertLessThanOrEqual(phase, 1)
        }
        XCTAssertEqual(first.primaryPhase, repeatedPrimary.primaryPhase, accuracy: 0.000_001)
        XCTAssertEqual(first.hotspotPhase, repeatedHotspot.hotspotPhase, accuracy: 0.000_001)
    }

    func testApproachDollyIsMonotonicCappedAndEased() {
        let start = InterstellarMotionSample.sample(at: 100, sessionStartedAt: 100)
        XCTAssertEqual(start.dollyProgress, 0, accuracy: 0.000_001)
        XCTAssertEqual(start.dollyScale, 1, accuracy: 0.000_001)

        let quarter = InterstellarMotionSample.sample(at: 102, sessionStartedAt: 100)
        let middle = InterstellarMotionSample.sample(at: 105, sessionStartedAt: 100)
        let done = InterstellarMotionSample.sample(at: 109, sessionStartedAt: 100)
        let later = InterstellarMotionSample.sample(at: 200, sessionStartedAt: 100)

        XCTAssertGreaterThan(quarter.dollyProgress, start.dollyProgress)
        XCTAssertGreaterThan(middle.dollyProgress, quarter.dollyProgress)
        XCTAssertEqual(done.dollyProgress, 1, accuracy: 0.000_001)
        XCTAssertEqual(
            done.dollyScale,
            1 + InterstellarMotionSample.approachScaleRange,
            accuracy: 0.000_001
        )
        XCTAssertEqual(later.dollyScale, done.dollyScale, accuracy: 0.000_001)
        XCTAssertEqual(start.dollyBrightness, 0, accuracy: 0.000_001)
        XCTAssertEqual(
            done.dollyBrightness,
            InterstellarMotionSample.approachBrightnessRange,
            accuracy: 0.000_001
        )

        // Ease-in: the first quarter of the session travels visibly less than
        // the linear share of the approach.
        let linearQuarterGain = InterstellarMotionSample.approachScaleRange * quarter.dollyProgress
        XCTAssertLessThan(quarter.dollyScale - 1, linearQuarterGain)
    }

    func testHotspotOrbitIsPeriodicAndHugsTheVisibleArc() {
        let base = InterstellarMotionSample.sample(at: 3.25)
        let repeated = InterstellarMotionSample.sample(
            at: 3.25 + InterstellarMotionSample.hotspotPeriod
        )
        XCTAssertEqual(base.hotspotPhase, repeated.hotspotPhase, accuracy: 0.000_001)

        let crest = InterstellarMotionSample.hotspotPoint(at: 0.45)
        XCTAssertGreaterThan(crest.x, 0.35)
        XCTAssertLessThan(crest.x, 0.85)
        XCTAssertGreaterThan(crest.y, -0.08)
        XCTAssertLessThan(crest.y, 0.35)
    }

    func testGravityTidePulseIsOneShotAndBounded() {
        let before = InterstellarMotionSample.sample(at: 9.8, pulseStartedAt: 10)
        let peak = InterstellarMotionSample.sample(at: 10.7, pulseStartedAt: 10)
        let after = InterstellarMotionSample.sample(at: 12, pulseStartedAt: 10)

        XCTAssertEqual(before.pulseStrength, 0)
        XCTAssertEqual(before.pulseProgress, 0)
        XCTAssertEqual(peak.pulseProgress, 0.5, accuracy: 0.000_001)
        XCTAssertEqual(peak.pulseStrength, 1, accuracy: 0.000_001)
        XCTAssertEqual(after.pulseStrength, 0)
        XCTAssertEqual(after.pulseProgress, 1)
    }
}
