import SpriteKit
import SwiftUI

enum OdysseyMotionPrototypeMode: String, CaseIterable {
    case off
    case automatic
    case cinematic

    static let environmentKey = "TOKENSTEP_ODYSSEY_MOTION_MODE"

    static var current: OdysseyMotionPrototypeMode {
        guard let value = ProcessInfo.processInfo.environment[environmentKey]?.lowercased(),
              let mode = OdysseyMotionPrototypeMode(rawValue: value)
        else {
            return .automatic
        }
        return mode
    }

    var preferredFramesPerSecond: Int {
        switch self {
        case .off: return 0
        case .automatic: return 12
        case .cinematic: return 24
        }
    }

    var particleIntensity: CGFloat {
        switch self {
        case .off: return 0
        case .automatic: return 1
        case .cinematic: return 1.42
        }
    }
}

enum OdysseyMotionPrototypeEligibility {
    static func shouldRender(
        isVoyage: Bool,
        chapter: TokenStepOdysseyChapter,
        mode: OdysseyMotionPrototypeMode,
        isSurfaceVisible: Bool,
        isScreenshotRendering: Bool
    ) -> Bool {
        isVoyage
            && chapter == .trojanInferno
            && mode != .off
            && isSurfaceVisible
            && !isScreenshotRendering
    }
}

struct OdysseyTrojanAmbientView: View {
    var mode: OdysseyMotionPrototypeMode
    var isSurfaceVisible: Bool
    var isScreenshotRendering: Bool

    @StateObject private var controller = OdysseyTrojanSceneController()

    private var shouldRender: Bool {
        OdysseyMotionPrototypeEligibility.shouldRender(
            isVoyage: TokenStepThemeRuntime.isVoyage,
            chapter: TokenStepThemeRuntime.odysseyChapter,
            mode: mode,
            isSurfaceVisible: isSurfaceVisible,
            isScreenshotRendering: isScreenshotRendering
        )
    }

    var body: some View {
        GeometryReader { proxy in
            if shouldRender {
                SpriteView(
                    scene: controller.scene,
                    isPaused: false,
                    preferredFramesPerSecond: mode.preferredFramesPerSecond,
                    options: [.allowsTransparency, .shouldCullNonVisibleNodes]
                )
                .onAppear {
                    controller.update(size: proxy.size, mode: mode, isActive: true)
                }
                .onChange(of: proxy.size) { _, newSize in
                    controller.update(size: newSize, mode: mode, isActive: true)
                }
                .onChange(of: mode) { _, newMode in
                    controller.update(size: proxy.size, mode: newMode, isActive: true)
                }
                .onDisappear {
                    controller.setRenderingActive(false)
                }
            }
        }
        .onChange(of: shouldRender) { _, active in
            controller.setRenderingActive(active)
        }
        .onDisappear {
            controller.setRenderingActive(false)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

final class OdysseyTrojanSceneController: ObservableObject {
    let scene: OdysseyTrojanParticleScene

    private let diagnosticsID: String
    private var currentMode: OdysseyMotionPrototypeMode = .automatic
    private var isRenderingActive = false

    init() {
        scene = OdysseyTrojanParticleScene(size: CGSize(width: 900, height: 590))
        diagnosticsID = String(UUID().uuidString.prefix(8))
        OdysseyMotionPrototypeDiagnostics.record(
            "scene_created",
            fields: [
                "emitters": String(scene.emitterNodeCount),
                "paused": String(scene.isPaused),
                "scene": diagnosticsID
            ]
        )
    }

    func update(
        size: CGSize,
        mode: OdysseyMotionPrototypeMode,
        isActive: Bool
    ) {
        currentMode = mode
        scene.updateCanvasSize(size)
        scene.apply(mode: mode)
        scene.setRenderingActive(isActive)
        recordTransitionIfNeeded(isActive)
    }

    func setRenderingActive(_ active: Bool) {
        scene.setRenderingActive(active)
        recordTransitionIfNeeded(active)
    }

    private func recordTransitionIfNeeded(_ active: Bool) {
        guard isRenderingActive != active else { return }
        isRenderingActive = active
        OdysseyMotionPrototypeDiagnostics.record(
            active ? "render_start" : "render_stop",
            fields: [
                "emitters": String(scene.emitterNodeCount),
                "fps": String(currentMode.preferredFramesPerSecond),
                "mode": currentMode.rawValue,
                "paused": String(scene.isPaused),
                "scene": diagnosticsID
            ]
        )
    }

    deinit {
        OdysseyMotionPrototypeDiagnostics.record(
            "scene_destroyed",
            fields: [
                "emitters": String(scene.emitterNodeCount),
                "paused": String(scene.isPaused),
                "scene": diagnosticsID
            ]
        )
    }
}
