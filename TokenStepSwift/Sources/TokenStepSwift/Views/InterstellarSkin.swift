import AppKit
import SwiftUI

enum InterstellarMotionPolicy {
    static let preferredFramesPerSecond = 24

    static func shouldAnimate(
        reduceMotion: Bool,
        isScreenshotRendering: Bool,
        isControlActive: Bool
    ) -> Bool {
        !reduceMotion && !isScreenshotRendering && isControlActive
    }
}

enum InterstellarArtwork {
    private static let hero = load(
        resource: "InterstellarEventHorizonHero",
        environmentKey: "TOKENSTEP_INTERSTELLAR_HERO_ART_PATH"
    )
    private static let quiet = load(
        resource: "InterstellarEventHorizonQuiet",
        environmentKey: "TOKENSTEP_INTERSTELLAR_QUIET_ART_PATH"
    )

    static func image(quiet prefersQuiet: Bool) -> NSImage? {
        prefersQuiet ? (quiet ?? hero) : (hero ?? quiet)
    }

    private static func load(resource: String, environmentKey: String) -> NSImage? {
        if let path = ProcessInfo.processInfo.environment[environmentKey],
           !path.isEmpty,
           let image = NSImage(contentsOfFile: path) {
            return image
        }
        if let url = Bundle.main.url(forResource: resource, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSImage(named: resource)
    }
}

struct InterstellarBackdrop: View {
    var role: OdysseySurfaceRole = .generic
    var isScreenshotRendering = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.controlActiveState) private var controlActiveState

    private var usesQuietArtwork: Bool {
        reduceMotion || [.history, .privacy, .settings, .update].contains(role)
    }

    private var motionEnabled: Bool {
        InterstellarMotionPolicy.shouldAnimate(
            reduceMotion: reduceMotion,
            isScreenshotRendering: isScreenshotRendering,
            isControlActive: controlActiveState != .inactive
        )
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color(red: 4 / 255, green: 7 / 255, blue: 12 / 255)

                if let artwork = InterstellarArtwork.image(quiet: usesQuietArtwork) {
                    Image(nsImage: artwork)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    InterstellarFallbackPlate()
                }

                InterstellarAccretionMotionLayer(isActive: motionEnabled)

                Color.black.opacity(roleVeilOpacity)

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.10),
                        Color.clear,
                        Color(red: 4 / 255, green: 7 / 255, blue: 12 / 255).opacity(0.62)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(bottomVeilOpacity)],
                    startPoint: .center,
                    endPoint: .bottom
                )
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var roleVeilOpacity: Double {
        switch role {
        case .popover: return 0.16
        case .dashboard: return 0.28
        case .share: return 0.12
        case .history: return 0.43
        case .privacy: return 0.52
        case .settings: return 0.50
        case .update: return 0.42
        case .island: return 0.30
        case .generic: return 0.36
        }
    }

    private var bottomVeilOpacity: Double {
        switch role {
        case .popover, .share: return 0.22
        default: return 0.44
        }
    }
}

private struct InterstellarAccretionMotionLayer: View {
    var isActive: Bool

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1 / Double(InterstellarMotionPolicy.preferredFramesPerSecond),
                paused: !isActive
            )
        ) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let phase = CGFloat(time.truncatingRemainder(dividingBy: 36) / 36)
                let breath = 0.5 + 0.5 * sin(time * 0.22)
                ZStack {
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.96, blue: 0.84).opacity(0.075 + breath * 0.035),
                            Color.clear
                        ],
                        center: UnitPoint(x: 0.42, y: 0.38),
                        startRadius: 2,
                        endRadius: max(proxy.size.width, proxy.size.height) * 0.28
                    )
                    .blendMode(.screen)

                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.00),
                            .init(color: Color.white.opacity(0.015), location: 0.35),
                            .init(color: Color(red: 1.0, green: 0.95, blue: 0.80).opacity(0.13), location: 0.49),
                            .init(color: Color.white.opacity(0.018), location: 0.64),
                            .init(color: .clear, location: 1.00)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.72, height: max(2, proxy.size.height * 0.012))
                    .blur(radius: 2.4)
                    .offset(
                        x: -proxy.size.width * 0.36 + phase * proxy.size.width * 1.08,
                        y: proxy.size.height * 0.015
                    )
                    .blendMode(.screen)

                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.055), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.34, height: 1)
                    .offset(
                        x: proxy.size.width * (0.18 - phase * 0.42),
                        y: proxy.size.height * 0.055
                    )
                    .blendMode(.screen)
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .opacity(isActive ? 1 : 0)
    }
}

private struct InterstellarFallbackPlate: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [Color.black, Color(red: 8 / 255, green: 13 / 255, blue: 20 / 255)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Circle()
                    .fill(Color.black)
                    .frame(width: proxy.size.width * 0.72)
                    .offset(x: -proxy.size.width * 0.30, y: -proxy.size.height * 0.18)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color(red: 1.0, green: 0.95, blue: 0.82), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width * 1.15, height: 4)
                    .shadow(color: Color.white.opacity(0.55), radius: 14)
            }
        }
    }
}

struct InterstellarPanelBackground: View {
    var opacity: Double = 0.70
    var cornerRadius: CGFloat = 18

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        shape
            .fill(Color(red: 8 / 255, green: 11 / 255, blue: 16 / 255).opacity(opacity))
            .overlay(shape.stroke(Color.tokenHairlineStrong.opacity(0.82), lineWidth: 1))
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color.tokenGreenDark.opacity(0.70), Color.tokenGreen.opacity(0.08), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 128, height: 1)
                .padding(.leading, 18)
            }
            .shadow(color: Color.black.opacity(0.30), radius: 18, y: 9)
    }
}

struct InterstellarWindowFrame: View {
    var inset: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
            ZStack {
                shape
                    .stroke(Color.tokenHairlineStrong.opacity(0.78), lineWidth: 1)
                    .padding(inset)
                ForEach(0..<4, id: \.self) { index in
                    let x = index < 2 ? inset + 16 : proxy.size.width - inset - 16
                    let y = index.isMultiple(of: 2) ? inset + 1 : proxy.size.height - inset - 1
                    Capsule()
                        .fill(Color.tokenGreenDark.opacity(0.66))
                        .frame(width: min(120, proxy.size.width * 0.16), height: 1)
                        .position(x: x + (index < 2 ? 48 : -48), y: y)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct InterstellarCardOrnament: View {
    var cornerRadius: CGFloat = 24

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(Color.tokenInnerHighlight.opacity(0.72), lineWidth: 1)
            .padding(1)
            .overlay(alignment: .topLeading) {
                Capsule()
                    .fill(Color.tokenGreenDark.opacity(0.64))
                    .frame(width: 82, height: 1)
                    .padding(.leading, 20)
            }
            .allowsHitTesting(false)
    }
}

struct InterstellarEventHorizonEmblem: View {
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Ellipse()
                    .stroke(Color.tokenGreenDark.opacity(0.42), lineWidth: 2)
                    .frame(width: proxy.size.width * 0.92, height: proxy.size.height * 0.24)
                    .rotationEffect(.degrees(-5))
                Circle()
                    .fill(Color.black.opacity(0.96))
                    .overlay(Circle().stroke(Color.tokenGreenDark.opacity(0.54), lineWidth: 1.5))
                    .frame(width: min(proxy.size.width, proxy.size.height) * 0.54)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.tokenGreenDark.opacity(0.9), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: proxy.size.width, height: 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct InterstellarTokenStepMark: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(Color(red: 7 / 255, green: 10 / 255, blue: 15 / 255))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                        .stroke(Color.tokenGreen.opacity(0.50), lineWidth: max(0.8, size * 0.02))
                )
            Ellipse()
                .stroke(Color.tokenGreenDark.opacity(0.86), lineWidth: max(1.2, size * 0.055))
                .frame(width: size * 0.72, height: size * 0.20)
                .shadow(color: Color.tokenGreenDark.opacity(0.30), radius: size * 0.08)
            Circle()
                .fill(Color.black)
                .overlay(Circle().stroke(Color.tokenGreenDark.opacity(0.72), lineWidth: max(0.7, size * 0.025)))
                .frame(width: size * 0.34, height: size * 0.34)
            Capsule()
                .fill(Color.tokenGreenDark)
                .frame(width: size * 0.68, height: max(1, size * 0.035))
        }
        .frame(width: size, height: size)
    }
}

struct InterstellarThemePreview: View {
    private let tileShape = RoundedRectangle(cornerRadius: 13, style: .continuous)
    private let warmWhite = Color(red: 1.0, green: 0.97, blue: 0.87)
    private let champagne = Color(red: 224 / 255, green: 207 / 255, blue: 169 / 255)

    var body: some View {
        ZStack {
            tileShape
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 3 / 255, green: 5 / 255, blue: 8 / 255),
                            Color(red: 11 / 255, green: 16 / 255, blue: 24 / 255)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [champagne.opacity(0.24), champagne.opacity(0.05), Color.clear],
                        center: .center,
                        startRadius: 1,
                        endRadius: 22
                    )
                )
                .frame(width: 46, height: 24)

            Ellipse()
                .stroke(
                    LinearGradient(
                        colors: [champagne.opacity(0.18), warmWhite, champagne.opacity(0.20)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.25
                )
                .frame(width: 42, height: 11)
                .shadow(color: warmWhite.opacity(0.24), radius: 2)

            InterstellarThemeLensingArcs()
                .stroke(
                    LinearGradient(
                        colors: [champagne.opacity(0.34), warmWhite.opacity(0.94), champagne.opacity(0.34)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 1.15, lineCap: .round)
                )
                .frame(width: 19, height: 28)

            Circle()
                .fill(Color.black)
                .frame(width: 18, height: 18)
                .overlay(
                    Circle()
                        .stroke(champagne.opacity(0.58), lineWidth: 0.75)
                )

            Capsule()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: champagne.opacity(0.72), location: 0.14),
                            .init(color: warmWhite, location: 0.50),
                            .init(color: champagne.opacity(0.72), location: 0.86),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 39, height: 1.5)
                .offset(y: 2.5)
                .shadow(color: warmWhite.opacity(0.36), radius: 1.4)
        }
        .clipShape(tileShape)
        .overlay(tileShape.stroke(champagne.opacity(0.46), lineWidth: 1))
        .accessibilityHidden(true)
    }
}

private struct InterstellarThemeLensingArcs: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let left = CGPoint(x: rect.minX, y: rect.midY - 1)
        let right = CGPoint(x: rect.maxX, y: rect.midY - 1)

        path.move(to: left)
        path.addCurve(
            to: right,
            control1: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.08),
            control2: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.minY + rect.height * 0.08)
        )

        path.move(to: CGPoint(x: rect.minX, y: rect.midY + 1))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY + 1),
            control1: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.08),
            control2: CGPoint(x: rect.maxX - rect.width * 0.12, y: rect.maxY - rect.height * 0.08)
        )

        return path
    }
}
