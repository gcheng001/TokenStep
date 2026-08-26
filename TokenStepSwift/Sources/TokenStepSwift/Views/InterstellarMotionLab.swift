import Foundation
import SwiftUI

enum InterstellarMotionMode: String, CaseIterable, Identifiable {
    case quiet
    case orbit
    case gravityTide = "gravity_tide"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiet: return "静谧"
        case .orbit: return "轨道"
        case .gravityTide: return "坠落"
        }
    }

    var preferredFramesPerSecond: Int {
        switch self {
        case .quiet: return 12
        case .orbit, .gravityTide: return 24
        }
    }

    var ambientIntensity: Double {
        switch self {
        case .quiet: return 0.85
        case .orbit: return 1.0
        case .gravityTide: return 1.15
        }
    }

    var breathAmplitude: Double {
        switch self {
        case .quiet: return 0.05
        case .orbit: return 0.07
        case .gravityTide: return 0.09
        }
    }

    var ambientBaseOpacity: Double {
        switch self {
        case .quiet: return 0.09
        case .orbit: return 0.115
        case .gravityTide: return 0.135
        }
    }

    var filamentCount: Int {
        switch self {
        case .quiet: return 0
        case .orbit: return 5
        case .gravityTide: return 6
        }
    }

    var starCount: Int {
        switch self {
        case .quiet: return 0
        case .orbit: return 10
        case .gravityTide: return 16
        }
    }

    var showsHotspot: Bool { self != .quiet }

    var usesApproach: Bool { self == .gravityTide }
}

enum InterstellarMotionLabConfiguration {
    static let modeKey = "TOKENSTEP_INTERSTELLAR_MOTION_MODE"
    static let previewTimeKey = "TOKENSTEP_INTERSTELLAR_PREVIEW_TIME"
    static let previewPulseStartedAtKey = "TOKENSTEP_INTERSTELLAR_PREVIEW_PULSE_START"

    /// Graduated in 0.2.9: the gravity motion lab ships with the Event Horizon
    /// theme. The remaining environment keys drive deterministic lab rendering.
    static var isEnabled: Bool { true }

    static var initialMode: InterstellarMotionMode {
        if let rawValue = ProcessInfo.processInfo.environment[modeKey],
           let mode = InterstellarMotionMode(rawValue: rawValue) {
            return mode
        }
        return isEnabled ? .gravityTide : .quiet
    }

    static var previewTime: TimeInterval? {
        ProcessInfo.processInfo.environment[previewTimeKey].flatMap(TimeInterval.init)
    }

    static var previewPulseStartedAt: TimeInterval? {
        ProcessInfo.processInfo.environment[previewPulseStartedAtKey].flatMap(TimeInterval.init)
    }
}

enum InterstellarMotionPolicy {
    static let preferredFramesPerSecond = 24
    static let lowPowerFramesPerSecond = 12

    static func framesPerSecond(mode: InterstellarMotionMode, lowPowerMode: Bool) -> Int {
        lowPowerMode
            ? min(lowPowerFramesPerSecond, mode.preferredFramesPerSecond)
            : mode.preferredFramesPerSecond
    }

    static func shouldAnimate(
        reduceMotion: Bool,
        isScreenshotRendering: Bool,
        isSurfaceVisible: Bool
    ) -> Bool {
        !reduceMotion && !isScreenshotRendering && isSurfaceVisible
    }
}

struct InterstellarMotionSample: Equatable {
    static let pulseDuration: TimeInterval = 1.4
    static let approachDuration: TimeInterval = 9
    static let hotspotPeriod: TimeInterval = 8

    /// Approach travel range over `approachDuration`; free-floating layers ride at 1.7x.
    /// The arc-glued hotspot scales with the plate so it never detaches from the disk.
    /// The pivot sits at the heart of the baked structure so the hole swells in
    /// place — edges rush out of frame while the arc crest climbs toward the top,
    /// which reads as the camera falling in rather than the plate sliding away.
    /// A gentle brightness swell rides along: closing in on a blazing disk.
    static let approachScaleRange: CGFloat = 0.36
    static let approachEaseExponent: CGFloat = 1.2
    static let approachBrightnessRange: Double = 0.16
    static let approachAnchor = UnitPoint(x: 0.46, y: 0.28)

    var primaryPhase: CGFloat
    var secondaryPhase: CGFloat
    var starPhase: CGFloat
    var breath: CGFloat
    var dollyProgress: CGFloat
    var hotspotPhase: CGFloat
    var pulseProgress: CGFloat
    var pulseStrength: CGFloat

    static func sample(
        at time: TimeInterval,
        sessionStartedAt: TimeInterval = 0,
        pulseStartedAt: TimeInterval? = nil
    ) -> InterstellarMotionSample {
        let pulse: (progress: CGFloat, strength: CGFloat)
        if let pulseStartedAt {
            let elapsed = time - pulseStartedAt
            if elapsed >= 0, elapsed <= pulseDuration {
                let progress = CGFloat(elapsed / pulseDuration)
                pulse = (progress, sin(.pi * progress))
            } else {
                pulse = (elapsed > pulseDuration ? 1 : 0, 0)
            }
        } else {
            pulse = (0, 0)
        }

        let sessionAge = max(0, time - sessionStartedAt)

        return InterstellarMotionSample(
            primaryPhase: unitPhase(time, period: 9),
            secondaryPhase: unitPhase(time, period: 14, offset: 4.5),
            starPhase: unitPhase(time, period: 11, offset: 7),
            breath: CGFloat(0.5 + 0.5 * sin(time * 2 * .pi / 8)),
            dollyProgress: CGFloat(min(1, sessionAge / approachDuration)),
            hotspotPhase: unitPhase(time, period: hotspotPeriod),
            pulseProgress: pulse.progress,
            pulseStrength: pulse.strength
        )
    }

    var dollyScale: CGFloat {
        1 + Self.approachScaleRange * pow(dollyProgress, Self.approachEaseExponent)
    }

    /// Brightness swell while closing in on the blazing disk.
    var dollyBrightness: Double {
        Self.approachBrightnessRange * pow(dollyProgress, Self.approachEaseExponent)
    }

    static func hotspotPoint(at phase: CGFloat) -> UnitPoint {
        let t = Double(wrapped(phase))

        // Cubic bezier fractions hugging the baked-in lensed arc across the
        // visible top band; the trailing descent along the right edge fades
        // out before leaving the frame.
        let start = (x: 0.26, y: -0.05)
        let control1 = (x: 0.43, y: 0.12)
        let control2 = (x: 0.70, y: -0.02)
        let end = (x: 1.05, y: 0.38)

        let inverse = 1 - t
        let a = inverse * inverse * inverse
        let b = 3 * inverse * inverse * t
        let c = 3 * inverse * t * t
        let d = t * t * t

        return UnitPoint(
            x: a * start.x + b * control1.x + c * control2.x + d * end.x,
            y: a * start.y + b * control1.y + c * control2.y + d * end.y
        )
    }

    private static func unitPhase(
        _ time: TimeInterval,
        period: TimeInterval,
        offset: TimeInterval = 0
    ) -> CGFloat {
        let raw = (time + offset).truncatingRemainder(dividingBy: period)
        let positive = raw < 0 ? raw + period : raw
        return CGFloat(positive / period)
    }
}

/// Renders one deterministic frame of the motion overlay from a sampled instant.
struct InterstellarMotionLayer: View {
    var mode: InterstellarMotionMode
    var sample: InterstellarMotionSample

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RadialGradient(
                    colors: [
                        warmWhite.opacity(
                            (mode.ambientBaseOpacity + Double(sample.breath) * mode.breathAmplitude)
                                * mode.ambientIntensity
                        ),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.44, y: 0.13),
                    startRadius: 2,
                    endRadius: max(proxy.size.width, proxy.size.height) * 0.36
                )
                .blendMode(.screen)

                InterstellarDiskFlow(mode: mode, sample: sample)

                if mode.starCount > 0 {
                    InterstellarFallingStars(count: mode.starCount, sample: sample)
                }

                if mode.usesApproach {
                    InterstellarGravityPulse(sample: sample)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var warmWhite: Color {
        Color(red: 1.0, green: 0.965, blue: 0.86)
    }
}

private struct InterstellarDiskFlow: View {
    var mode: InterstellarMotionMode
    var sample: InterstellarMotionSample

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<mode.filamentCount, id: \.self) { index in
                    let directionPhase = index.isMultiple(of: 2)
                        ? wrapped(sample.primaryPhase + CGFloat(index) * 0.23)
                        : wrapped(1 - sample.secondaryPhase + CGFloat(index) * 0.19)
                    let width = proxy.size.width * (0.30 + CGFloat(index % 3) * 0.10)
                    let height = CGFloat(1.4 + Double(index % 3) * 1.1)
                    // Ride the visible band just under the baked accretion arc.
                    let yOffset = CGFloat(index - mode.filamentCount / 2) * 0.018
                    let opacity = (0.22 + Double(index % 3) * 0.055) * mode.ambientIntensity

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: champagne.opacity(opacity * 0.45), location: 0.20),
                            .init(color: warmWhite.opacity(opacity), location: 0.52),
                            .init(color: champagne.opacity(opacity * 0.52), location: 0.82),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: width, height: height)
                    .blur(radius: index.isMultiple(of: 3) ? 1.8 : 0.7)
                    .position(
                        x: -width * 0.35 + directionPhase * (proxy.size.width + width * 0.7),
                        y: proxy.size.height * (0.085 + yOffset)
                    )
                    .blendMode(.screen)
                }

                LinearGradient(
                    colors: [Color.clear, warmWhite.opacity(0.10 * mode.ambientIntensity), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: proxy.size.width * 0.56, height: 1.2)
                .position(
                    x: proxy.size.width * (1.04 - sample.secondaryPhase * 1.16),
                    y: proxy.size.height * 0.905
                )
                .blendMode(.screen)
            }
        }
    }

    private var warmWhite: Color {
        Color(red: 1.0, green: 0.965, blue: 0.86)
    }

    private var champagne: Color {
        Color(red: 224 / 255, green: 207 / 255, blue: 169 / 255)
    }
}

/// A white-hot plasma knot that orbits along the baked-in lensed arc, trailing
/// a soft comet tail. Glued to the plate (same scale factor) so it stays on
/// the arc during the approach; fades out before the right-edge descent.
struct InterstellarHotspotOrbit: View {
    var mode: InterstellarMotionMode
    var sample: InterstellarMotionSample

    var body: some View {
        GeometryReader { proxy in
            let phase = sample.hotspotPhase
            let point = InterstellarMotionSample.hotspotPoint(at: phase)
            let position = CGPoint(
                x: proxy.size.width * point.x,
                y: proxy.size.height * point.y
            )
            let fadeIn = min(1, Double(phase) / 0.08)
            let fadeOut = min(1, max(0, (0.95 - Double(phase)) / 0.18))
            let fade = min(fadeIn, fadeOut)
            let tailWidth: CGFloat = mode.usesApproach ? 3.0 : 2.4

            ZStack {
                InterstellarOrbitCurve()
                    .trim(from: max(0, phase - 0.12), to: min(1, phase))
                    .stroke(
                        LinearGradient(
                            colors: [
                                .clear,
                                warmWhite.opacity(0.42 * fade),
                                champagne.opacity(0.24 * fade)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: tailWidth, lineCap: .round)
                    )
                    .blur(radius: 3)
                    .blendMode(.screen)

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                warmWhite.opacity(0.75 * fade),
                                champagne.opacity(0.28 * fade),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0.5,
                            endRadius: 16
                        )
                    )
                    .frame(width: 34, height: 19)
                    .position(position)
                    .blur(radius: 0.6)
                    .blendMode(.screen)

                Ellipse()
                    .fill(warmWhite.opacity(0.95 * fade))
                    .frame(width: 4.0, height: 2.4)
                    .shadow(color: warmWhite.opacity(0.80 * fade), radius: 4)
                    .position(position)
                    .blendMode(.screen)
            }
        }
        .opacity(mode.showsHotspot ? 1 : 0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var warmWhite: Color {
        Color(red: 1.0, green: 0.965, blue: 0.86)
    }

    private var champagne: Color {
        Color(red: 224 / 255, green: 207 / 255, blue: 169 / 255)
    }
}

/// Same bezier fractions as `InterstellarMotionSample.hotspotPoint(at:)`.
private struct InterstellarOrbitCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(
            to: CGPoint(x: rect.width * 0.26, y: rect.height * -0.05)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 1.05, y: rect.height * 0.38),
            control1: CGPoint(x: rect.width * 0.43, y: rect.height * 0.12),
            control2: CGPoint(x: rect.width * 0.70, y: rect.height * -0.02)
        )
        return path
    }
}

private struct InterstellarFallingStars: View {
    var count: Int
    var sample: InterstellarMotionSample

    var body: some View {
        Canvas { context, size in
            for index in 0..<count {
                let seedX = seeded(index, multiplier: 12.9898)
                let seedY = seeded(index + 17, multiplier: 78.233)
                let progress = wrapped(sample.starPhase + seedX)
                let gravity = pow(progress, 1.65)
                let startY = 0.03 + seedY * 0.24
                let endY = 0.10 + seedY * 0.09
                let oscillation = sin((Double(progress) + Double(seedY)) * 2 * .pi)
                    * 0.018 * Double(1 - progress)
                let x = size.width * (0.96 - progress * 0.70)
                let y = size.height * (
                    startY * (1 - gravity)
                    + endY * gravity
                    + CGFloat(oscillation)
                )
                let visibility = max(0, sin(.pi * Double(progress)))
                let radius = 1.0 + seedX * 1.7
                let rect = CGRect(
                    x: x - radius,
                    y: y - radius,
                    width: radius * 2,
                    height: radius * 2
                )
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(
                        Color(red: 1.0, green: 0.97, blue: 0.88)
                            .opacity(visibility * (0.30 + Double(seedY) * 0.50))
                    )
                )
            }
        }
        .blendMode(.screen)
    }

    private func seeded(_ value: Int, multiplier: Double) -> CGFloat {
        let raw = sin(Double(value + 1) * multiplier) * 43_758.5453
        return CGFloat(raw - floor(raw))
    }
}

/// One-shot feeding wavefront that travels out of the event-horizon region;
/// triggered on open, token growth, or the manual lab button.
private struct InterstellarGravityPulse: View {
    var sample: InterstellarMotionSample

    var body: some View {
        GeometryReader { proxy in
            let strength = Double(sample.pulseStrength)
            let progress = sample.pulseProgress
            let center = CGPoint(x: proxy.size.width * 0.235, y: proxy.size.height * 0.105)
            ZStack {
                RadialGradient(
                    colors: [
                        warmWhite.opacity(strength * 0.28),
                        champagne.opacity(strength * 0.10),
                        .clear
                    ],
                    center: UnitPoint(x: 0.235, y: 0.105),
                    startRadius: 1,
                    endRadius: max(proxy.size.width, proxy.size.height) * (0.10 + progress * 0.48)
                )
                .blendMode(.screen)

                ForEach(0..<2, id: \.self) { index in
                    let delayed = max(0, min(1, progress - CGFloat(index) * 0.12))
                    Ellipse()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    warmWhite.opacity(strength * (index == 0 ? 0.60 : 0.30)),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: index == 0 ? 1.8 : 0.9
                        )
                        .frame(
                            width: proxy.size.width * (0.18 + delayed * 1.05),
                            height: proxy.size.height * (0.05 + delayed * 0.34)
                        )
                        .position(center)
                        .blur(radius: index == 0 ? 1.4 : 0.8)
                }

                LinearGradient(
                    colors: [
                        Color.clear,
                        warmWhite.opacity(strength * 0.66),
                        champagne.opacity(strength * 0.24),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: proxy.size.width * 0.56, height: 3)
                .position(x: proxy.size.width * 0.33, y: proxy.size.height * 0.108)
                .blur(radius: 2)
                .blendMode(.screen)
            }
            .opacity(sample.pulseStrength > 0 ? 1 : 0)
        }
    }

    private var warmWhite: Color {
        Color(red: 1.0, green: 0.965, blue: 0.86)
    }

    private var champagne: Color {
        Color(red: 224 / 255, green: 207 / 255, blue: 169 / 255)
    }
}

struct InterstellarMotionLabPicker: View {
    @Binding var mode: InterstellarMotionMode
    var triggerPulse: () -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(InterstellarMotionMode.allCases) { candidate in
                Button {
                    mode = candidate
                } label: {
                    Text(candidate.title)
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(candidate == mode ? Color.black : Color.tokenInk.opacity(0.66))
                        .frame(width: 34, height: 22)
                        .background(
                            candidate == mode ? Color.tokenGreenDark : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .help("引力动效：\(candidate.title)")
            }

            Button(action: triggerPulse) {
                Image(systemName: "waveform.path.ecg")
                    .font(.system(size: 9, weight: .black))
                    .foregroundStyle(Color.tokenGreenDark)
                    .frame(width: 24, height: 22)
            }
            .buttonStyle(.plain)
            .disabled(mode != .gravityTide)
            .opacity(mode == .gravityTide ? 1 : 0.34)
            .help("触发一次 Token 坠落事件")
        }
        .padding(3)
        .background(Color.black.opacity(0.44), in: Capsule())
        .overlay(Capsule().stroke(Color.tokenHairlineStrong.opacity(0.70), lineWidth: 1))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("引力动效实验室")
    }
}

func wrapped(_ value: CGFloat) -> CGFloat {
    let remainder = value.truncatingRemainder(dividingBy: 1)
    return remainder < 0 ? remainder + 1 : remainder
}
