import AppKit
import SwiftUI

struct OdysseySurfaceVisibilityReader: NSViewRepresentable {
    @Binding var isVisible: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator { value in
            isVisible = value
        }
    }

    func makeNSView(context: Context) -> OdysseyVisibilityProbeView {
        let view = OdysseyVisibilityProbeView()
        view.onWindowChange = { window in
            context.coordinator.attach(to: window)
        }
        return view
    }

    func updateNSView(_ nsView: OdysseyVisibilityProbeView, context: Context) {
        context.coordinator.onVisibilityChange = { value in
            isVisible = value
        }
        context.coordinator.attach(to: nsView.window)
    }

    static func dismantleNSView(_ nsView: OdysseyVisibilityProbeView, coordinator: Coordinator) {
        nsView.onWindowChange = nil
        coordinator.detach()
    }

    final class Coordinator {
        var onVisibilityChange: (Bool) -> Void

        private weak var observedWindow: NSWindow?
        private var notificationTokens: [NSObjectProtocol] = []
        private var visibilityObservation: NSKeyValueObservation?
        private var lastPublishedValue: Bool?

        init(onVisibilityChange: @escaping (Bool) -> Void) {
            self.onVisibilityChange = onVisibilityChange
        }

        func attach(to window: NSWindow?) {
            guard observedWindow !== window else {
                publishCurrentState()
                return
            }

            removeObservers()
            observedWindow = window

            guard let window else {
                publish(false)
                return
            }

            visibilityObservation = window.observe(\.isVisible, options: [.initial, .new]) { [weak self] _, _ in
                DispatchQueue.main.async {
                    self?.publishCurrentState()
                }
            }

            let names: [Notification.Name] = [
                NSWindow.didBecomeKeyNotification,
                NSWindow.didResignKeyNotification,
                NSWindow.didChangeOcclusionStateNotification,
                NSWindow.didMiniaturizeNotification,
                NSWindow.didDeminiaturizeNotification,
                NSWindow.willCloseNotification
            ]

            notificationTokens = names.map { name in
                NotificationCenter.default.addObserver(
                    forName: name,
                    object: window,
                    queue: .main
                ) { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.publishCurrentState()
                    }
                }
            }

            publishCurrentState()
        }

        func detach() {
            removeObservers()
            observedWindow = nil
            publish(false)
        }

        private func publishCurrentState() {
            guard let window = observedWindow else {
                publish(false)
                return
            }

            let visible = window.isVisible
                && !window.isMiniaturized
                && window.occlusionState.contains(.visible)
            publish(visible)
        }

        private func publish(_ value: Bool) {
            guard lastPublishedValue != value else { return }
            lastPublishedValue = value
            OdysseyMotionPrototypeDiagnostics.record(
                "surface_visibility",
                fields: ["visible": String(value)]
            )
            DispatchQueue.main.async { [weak self] in
                self?.onVisibilityChange(value)
            }
        }

        private func removeObservers() {
            visibilityObservation?.invalidate()
            visibilityObservation = nil
            notificationTokens.forEach(NotificationCenter.default.removeObserver)
            notificationTokens.removeAll()
        }

        deinit {
            removeObservers()
        }
    }
}

final class OdysseyVisibilityProbeView: NSView {
    var onWindowChange: ((NSWindow?) -> Void)?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        onWindowChange?(window)
    }
}
