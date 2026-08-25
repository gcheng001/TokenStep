import AppKit
import Darwin
import XCTest
@testable import TokenStepSwift

final class OdysseyMotionPrototypeTests: XCTestCase {
    func testPrototypeModesExposeExpectedProfiles() {
        XCTAssertEqual(OdysseyMotionPrototypeMode.off.preferredFramesPerSecond, 0)
        XCTAssertEqual(OdysseyMotionPrototypeMode.automatic.preferredFramesPerSecond, 12)
        XCTAssertEqual(OdysseyMotionPrototypeMode.cinematic.preferredFramesPerSecond, 24)
        XCTAssertEqual(OdysseyMotionPrototypeMode.off.particleIntensity, 0)
        XCTAssertGreaterThan(
            OdysseyMotionPrototypeMode.cinematic.particleIntensity,
            OdysseyMotionPrototypeMode.automatic.particleIntensity
        )
    }

    func testEligibilityRequiresTrojanVisibleVoyageSurfaceAndSuppressesScreenshots() {
        XCTAssertTrue(eligibility())
        XCTAssertFalse(eligibility(isVoyage: false))
        XCTAssertFalse(eligibility(chapter: .aegeanMist))
        XCTAssertFalse(eligibility(mode: .off))
        XCTAssertFalse(eligibility(isSurfaceVisible: false))
        XCTAssertFalse(eligibility(isScreenshotRendering: true))
    }

    func testSceneKeepsConfiguredEmitterSetAcrossThirtyVisibilityCycles() async {
        await MainActor.run {
            let scene = OdysseyTrojanParticleScene(size: CGSize(width: 900, height: 590))
            XCTAssertEqual(
                scene.emitterNodeCount,
                OdysseyTrojanParticleScene.expectedEmitterNodeCount
            )

            scene.apply(mode: .automatic)
            let automaticFireRate = scene.birthRate(for: .fire)
            scene.apply(mode: .cinematic)
            XCTAssertGreaterThan(scene.birthRate(for: .fire), automaticFireRate)

            for _ in 0..<30 {
                scene.setRenderingActive(true)
                XCTAssertFalse(scene.isPaused)
                scene.setRenderingActive(false)
                XCTAssertTrue(scene.isPaused)
                XCTAssertEqual(
                    scene.emitterNodeCount,
                    OdysseyTrojanParticleScene.expectedEmitterNodeCount
                )
            }

            scene.updateCanvasSize(CGSize(width: 720, height: 480))
            XCTAssertEqual(scene.size, CGSize(width: 720, height: 480))
            XCTAssertEqual(
                scene.emitterNodeCount,
                OdysseyTrojanParticleScene.expectedEmitterNodeCount
            )

            scene.apply(mode: .off)
            for layer in OdysseyTrojanParticleLayer.allCases {
                XCTAssertEqual(scene.birthRate(for: layer), 0, accuracy: 0.0001)
            }
        }
    }

    @MainActor
    func testWindowVisibilityObserverTracksOrderFrontAndOrderOutWithoutPolling() async throws {
        _ = NSApplication.shared
        var observedValues: [Bool] = []
        let coordinator = OdysseySurfaceVisibilityReader.Coordinator {
            observedValues.append($0)
        }
        let window = NSWindow(
            contentRect: CGRect(x: 10, y: 10, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.alphaValue = 0

        coordinator.attach(to: window)
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertEqual(observedValues.last, false)

        window.orderFront(nil)
        try await Task.sleep(nanoseconds: 80_000_000)
        XCTAssertEqual(observedValues.last, true)

        window.orderOut(nil)
        try await Task.sleep(nanoseconds: 80_000_000)
        XCTAssertEqual(observedValues.last, false)

        coordinator.detach()
    }

    func testDiagnosticsWritesTransitionLogOnlyWhenExplicitlyEnabled() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("tokenstep-odyssey-motion-diagnostics-\(UUID().uuidString)")
        let logURL = directory.appendingPathComponent("events.log")
        let key = OdysseyMotionPrototypeDiagnostics.environmentKey
        let previousValue = getenv(key).map { String(cString: $0) }

        setenv(key, logURL.path, 1)
        defer {
            if let previousValue {
                setenv(key, previousValue, 1)
            } else {
                unsetenv(key)
            }
            try? FileManager.default.removeItem(at: directory)
        }

        OdysseyMotionPrototypeDiagnostics.record(
            "render_stop",
            fields: [
                "emitters": String(OdysseyTrojanParticleScene.expectedEmitterNodeCount),
                "paused": "true"
            ]
        )

        let content = try String(contentsOf: logURL, encoding: .utf8)
        XCTAssertTrue(content.contains("event=render_stop"))
        XCTAssertTrue(
            content.contains("emitters=\(OdysseyTrojanParticleScene.expectedEmitterNodeCount)")
        )
        XCTAssertTrue(content.contains("paused=true"))
        XCTAssertTrue(content.contains("uptime_ns="))
    }

    private func eligibility(
        isVoyage: Bool = true,
        chapter: TokenStepOdysseyChapter = .trojanInferno,
        mode: OdysseyMotionPrototypeMode = .automatic,
        isSurfaceVisible: Bool = true,
        isScreenshotRendering: Bool = false
    ) -> Bool {
        OdysseyMotionPrototypeEligibility.shouldRender(
            isVoyage: isVoyage,
            chapter: chapter,
            mode: mode,
            isSurfaceVisible: isSurfaceVisible,
            isScreenshotRendering: isScreenshotRendering
        )
    }
}
