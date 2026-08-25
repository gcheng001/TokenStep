import AppKit
import SwiftUI

enum OdysseySurfaceRole: String {
    case generic
    case popover
    case dashboard
    case history
    case privacy
    case settings
    case share
    case update
    case island
}

private enum OdysseyMotif {
    case helmet
    case horse
    case marble
}

private extension TokenStepOdysseyChapter {
    func motif(for role: OdysseySurfaceRole) -> OdysseyMotif {
        switch self {
        case .aegeanMist:
            return .helmet
        case .trojanInferno:
            return .horse
        case .ashMarble:
            return .marble
        case .directorsCut:
            switch role {
            case .popover, .island:
                return .helmet
            case .history, .privacy, .settings:
                return .marble
            case .dashboard, .share, .update, .generic:
                return .horse
            }
        }
    }
}

struct VoyageBowProgressView: View {
    var progress: Double
    var lineWidth: CGFloat = 12
    var color: Color = .tokenGreen

    var body: some View {
        Canvas { context, size in
            let clamped = min(max(progress, 0), 1)
            let diameter = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = diameter / 2 - lineWidth
            let startDegrees = 58.0
            let endDegrees = startDegrees - 360 * clamped

            var track = Path()
            track.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(360),
                clockwise: false
            )
            context.stroke(
                track,
                with: .color(Color.tokenTrack.opacity(0.86)),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )

            var arc = Path()
            arc.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(startDegrees),
                endAngle: .degrees(endDegrees),
                clockwise: true
            )
            context.stroke(
                arc,
                with: .color(color),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )

            let startPoint = point(center: center, radius: radius, degrees: startDegrees)
            let nockSize = lineWidth * 0.58
            context.fill(
                Path(ellipseIn: CGRect(
                    x: startPoint.x - nockSize / 2,
                    y: startPoint.y - nockSize / 2,
                    width: nockSize,
                    height: nockSize
                )),
                with: .color(Color.tokenGreenDark)
            )

            let endpoint = point(center: center, radius: radius, degrees: endDegrees)
            let radians = CGFloat(endDegrees * .pi / 180)
            let tangent = CGPoint(x: sin(radians), y: -cos(radians))
            let normal = CGPoint(x: -tangent.y, y: tangent.x)
            let tip = CGPoint(
                x: endpoint.x + tangent.x * lineWidth * 0.86,
                y: endpoint.y + tangent.y * lineWidth * 0.86
            )
            let baseCenter = CGPoint(
                x: endpoint.x - tangent.x * lineWidth * 0.32,
                y: endpoint.y - tangent.y * lineWidth * 0.32
            )
            var arrowhead = Path()
            arrowhead.move(to: tip)
            arrowhead.addLine(to: CGPoint(
                x: baseCenter.x + normal.x * lineWidth * 0.54,
                y: baseCenter.y + normal.y * lineWidth * 0.54
            ))
            arrowhead.addLine(to: CGPoint(
                x: baseCenter.x - normal.x * lineWidth * 0.54,
                y: baseCenter.y - normal.y * lineWidth * 0.54
            ))
            arrowhead.closeSubpath()
            context.fill(arrowhead, with: .color(Color.tokenGreenDark))

            let gripRect = CGRect(
                x: center.x + radius - lineWidth * 0.38,
                y: center.y - lineWidth * 0.72,
                width: lineWidth * 0.76,
                height: lineWidth * 1.44
            )
            context.fill(
                Path(roundedRect: gripRect, cornerRadius: lineWidth * 0.28),
                with: .color(Color(red: 106 / 255, green: 62 / 255, blue: 36 / 255))
            )
            context.stroke(
                Path(roundedRect: gripRect, cornerRadius: lineWidth * 0.28),
                with: .color(Color.tokenGreenDark.opacity(0.72)),
                lineWidth: max(0.8, lineWidth * 0.09)
            )
        }
        .accessibilityHidden(true)
    }

    private func point(center: CGPoint, radius: CGFloat, degrees: Double) -> CGPoint {
        let radians = CGFloat(degrees * .pi / 180)
        return CGPoint(
            x: center.x + cos(radians) * radius,
            y: center.y + sin(radians) * radius
        )
    }
}

struct VoyageRivetedDivider: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.tokenDivider)
                .frame(width: 1)
            VStack {
                rivet
                Spacer()
                rivet
                Spacer()
                rivet
            }
            .padding(.vertical, 5)
        }
        .frame(width: 1)
        .allowsHitTesting(false)
    }

    private var rivet: some View {
        Circle()
            .fill(Color.tokenGreenDark)
            .overlay(Circle().stroke(Color.black.opacity(0.55), lineWidth: 0.8))
            .frame(width: 6, height: 6)
    }
}

struct VoyageRouteWatermark: View {
    var body: some View {
        Canvas { context, size in
            var route = Path()
            route.move(to: CGPoint(x: size.width * 0.06, y: size.height * 0.78))
            route.addCurve(
                to: CGPoint(x: size.width * 0.46, y: size.height * 0.53),
                control1: CGPoint(x: size.width * 0.20, y: size.height * 0.76),
                control2: CGPoint(x: size.width * 0.30, y: size.height * 0.66)
            )
            route.addCurve(
                to: CGPoint(x: size.width * 0.90, y: size.height * 0.15),
                control1: CGPoint(x: size.width * 0.62, y: size.height * 0.38),
                control2: CGPoint(x: size.width * 0.78, y: size.height * 0.24)
            )
            context.stroke(
                route,
                with: .color(Color.tokenGreen.opacity(0.18)),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [4, 6])
            )

            for point in [
                CGPoint(x: size.width * 0.24, y: size.height * 0.70),
                CGPoint(x: size.width * 0.51, y: size.height * 0.49),
                CGPoint(x: size.width * 0.76, y: size.height * 0.27)
            ] {
                context.fill(
                    Path(ellipseIn: CGRect(x: point.x - 2.5, y: point.y - 2.5, width: 5, height: 5)),
                    with: .color(Color.tokenGreenDark.opacity(0.30))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct VoyageHelmetRelief: View {
    var body: some View {
        Canvas { context, size in
            var crest = Path()
            crest.move(to: CGPoint(x: size.width * 0.16, y: size.height * 0.37))
            crest.addCurve(
                to: CGPoint(x: size.width * 0.86, y: size.height * 0.34),
                control1: CGPoint(x: size.width * 0.38, y: size.height * 0.05),
                control2: CGPoint(x: size.width * 0.72, y: size.height * 0.08)
            )
            context.stroke(crest, with: .color(Color.tokenGreenDark.opacity(0.34)), lineWidth: 2.2)

            var helmet = Path()
            helmet.move(to: CGPoint(x: size.width * 0.28, y: size.height * 0.78))
            helmet.addLine(to: CGPoint(x: size.width * 0.32, y: size.height * 0.43))
            helmet.addCurve(
                to: CGPoint(x: size.width * 0.78, y: size.height * 0.48),
                control1: CGPoint(x: size.width * 0.44, y: size.height * 0.27),
                control2: CGPoint(x: size.width * 0.69, y: size.height * 0.30)
            )
            helmet.addLine(to: CGPoint(x: size.width * 0.64, y: size.height * 0.57))
            helmet.addLine(to: CGPoint(x: size.width * 0.53, y: size.height * 0.82))
            helmet.addLine(to: CGPoint(x: size.width * 0.39, y: size.height * 0.69))
            helmet.addLine(to: CGPoint(x: size.width * 0.28, y: size.height * 0.78))
            context.stroke(
                helmet,
                with: .color(Color.tokenGreenDark.opacity(0.36)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )

            var eye = Path()
            eye.move(to: CGPoint(x: size.width * 0.39, y: size.height * 0.51))
            eye.addLine(to: CGPoint(x: size.width * 0.67, y: size.height * 0.49))
            context.stroke(eye, with: .color(Color.tokenGreenDark.opacity(0.42)), lineWidth: 1.6)
        }
        .allowsHitTesting(false)
    }
}

struct TokenStepBrandLockup: View {
    var markSize: CGFloat = 28
    var titleSize: CGFloat = 17
    var showsEdition = true

    var body: some View {
        HStack(spacing: max(8, markSize * 0.30)) {
            TokenStepMark(size: markSize)

            VStack(alignment: .leading, spacing: TokenStepThemeRuntime.isVoyage && showsEdition ? 1 : 0) {
                Text("TokenStep")
                    .font(.system(size: titleSize, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.tokenInk)
                    .tracking(TokenStepThemeRuntime.isVoyage ? 0.2 : 0)

                if TokenStepThemeRuntime.isVoyage && showsEdition {
                    HStack(spacing: 5) {
                        Rectangle()
                            .fill(Color.tokenGreen)
                            .frame(width: 12, height: 1)
                        Text(TokenStepThemeRuntime.odysseyChapter.editionLabel)
                            .font(.system(size: max(7, titleSize * 0.47), weight: .bold, design: .serif))
                            .tracking(1.35)
                            .foregroundStyle(Color.tokenGreenDark.opacity(0.84))
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("TokenStep")
    }
}

struct OdysseyPopoverBackdrop: View {
    var motionMode: OdysseyMotionPrototypeMode = .current
    var isMotionSurfaceActive = false
    var isScreenshotRendering = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.tokenCanvas

                if let artwork = OdysseyPopoverArtwork.image(for: TokenStepThemeRuntime.odysseyChapter) {
                    Image(nsImage: artwork)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                } else {
                    VoyageBackdropAtmosphere(role: .popover)
                }

                if TokenStepThemeRuntime.odysseyChapter == .trojanInferno,
                   motionMode != .off,
                   !isScreenshotRendering {
                    OdysseyTrojanAmbientView(
                        mode: motionMode,
                        isSurfaceVisible: isMotionSurfaceActive,
                        isScreenshotRendering: false
                    )
                }

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.04),
                        Color.tokenCanvas.opacity(0.08),
                        Color.tokenCanvas.opacity(0.34),
                        Color.tokenCanvas.opacity(0.58)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )

                LinearGradient(
                    colors: [
                        Color.tokenCanvas.opacity(0.12),
                        Color.clear,
                        Color.tokenCanvas.opacity(0.48)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                OdysseyPopoverFilmTexture()
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct OdysseyPopoverSectionBackground: View {
    var opacity: Double = 0.50
    var cornerRadius: CGFloat = 18

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.tokenCanvas.opacity(opacity))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.tokenHairlineStrong.opacity(0.86), lineWidth: 1)
            }
            .overlay(alignment: .topLeading) {
                LinearGradient(
                    colors: [Color.tokenGreen.opacity(0.56), Color.tokenGreen.opacity(0.08), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 92, height: 1)
                .padding(.leading, 16)
            }
            .shadow(color: Color.black.opacity(0.22), radius: 14, y: 7)
    }
}

struct OdysseyPopoverWindowFrame: View {
    var inset: CGFloat = 7

    var body: some View {
        GeometryReader { proxy in
            let outer = RoundedRectangle(cornerRadius: 22, style: .continuous)
            let inner = RoundedRectangle(cornerRadius: 18, style: .continuous)

            ZStack {
                outer
                    .stroke(Color.tokenHairlineStrong.opacity(0.90), lineWidth: 1.15)
                    .padding(inset)

                inner
                    .stroke(Color.tokenInnerHighlight.opacity(0.48), lineWidth: 0.6)
                    .padding(inset + 3)

                Path { path in
                    path.move(to: CGPoint(x: inset + 24, y: inset + 1))
                    path.addLine(to: CGPoint(x: min(proxy.size.width * 0.25, inset + 160), y: inset + 1))
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.tokenGreen, Color.tokenGreen.opacity(0.04)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1.6
                )

                Path { path in
                    path.move(to: CGPoint(x: proxy.size.width - inset - 24, y: proxy.size.height - inset - 1))
                    path.addLine(to: CGPoint(x: max(proxy.size.width * 0.78, proxy.size.width - inset - 150), y: proxy.size.height - inset - 1))
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.tokenGreen, Color.tokenGreen.opacity(0.04)],
                        startPoint: .trailing,
                        endPoint: .leading
                    ),
                    lineWidth: 1.2
                )
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private enum OdysseyPopoverArtwork {
    static let aegean = load(
        resource: "OdysseyAegeanPopover",
        environmentKey: "TOKENSTEP_ODYSSEY_AEGEAN_ART_PATH"
    )
    static let trojan = load(
        resource: "OdysseyTrojanPopover",
        environmentKey: "TOKENSTEP_ODYSSEY_TROJAN_ART_PATH"
    )
    static let ashMarble = load(
        resource: "OdysseyAshMarblePopover",
        environmentKey: "TOKENSTEP_ODYSSEY_ASH_ART_PATH"
    )

    static func image(for chapter: TokenStepOdysseyChapter) -> NSImage? {
        switch chapter {
        case .directorsCut, .aegeanMist:
            return aegean
        case .trojanInferno:
            return trojan
        case .ashMarble:
            return ashMarble
        }
    }

    private static func load(resource: String, environmentKey: String) -> NSImage? {
        if let path = ProcessInfo.processInfo.environment[environmentKey],
           let image = NSImage(contentsOfFile: path) {
            return image
        }
        if let url = Bundle.main.url(forResource: resource, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return nil
    }
}

private struct OdysseyPopoverFilmTexture: View {
    var body: some View {
        Canvas { context, size in
            let columns = max(1, Int(size.width / 23))
            let rows = max(1, Int(size.height / 23))
            for column in 0...columns {
                for row in 0...rows where (column * 13 + row * 7) % 11 == 0 {
                    let x = CGFloat(column) * 23 + CGFloat((row * 3) % 9)
                    let y = CGFloat(row) * 23 + CGFloat((column * 5) % 11)
                    let bright = (column + row) % 5 == 0
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: bright ? 1.3 : 0.8, height: bright ? 1.3 : 0.8)),
                        with: .color(bright ? Color.tokenGreen.opacity(0.10) : Color.white.opacity(0.025))
                    )
                }
            }
        }
    }
}

struct VoyageBackdropAtmosphere: View {
    var role: OdysseySurfaceRole = .generic

    private var motif: OdysseyMotif {
        TokenStepThemeRuntime.odysseyChapter.motif(for: role)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                atmosphericGlow

                OdysseyAtmosphericTexture(motif: motif)

                motifLayer
                    .frame(
                        width: min(max(proxy.size.width * 0.38, 180), 520),
                        height: min(max(proxy.size.height * 0.78, 150), 520)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: motifAlignment)
                    .padding(.trailing, max(12, proxy.size.width * 0.025))
                    .padding(.bottom, max(8, proxy.size.height * 0.02))

                if motif == .marble {
                    OdysseyGreekKeyBand()
                        .frame(height: 18)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .opacity(0.34)
                } else {
                    VoyageRouteWatermark()
                        .opacity(motif == .helmet ? 0.20 : 0.09)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 26)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var atmosphericGlow: some View {
        switch motif {
        case .helmet:
            ZStack {
                RadialGradient(
                    colors: [Color(red: 83 / 255, green: 130 / 255, blue: 157 / 255).opacity(0.24), Color.clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 520
                )
                LinearGradient(
                    colors: [Color(red: 132 / 255, green: 164 / 255, blue: 181 / 255).opacity(0.06), Color.clear, Color.tokenGreen.opacity(0.035)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        case .horse:
            ZStack {
                RadialGradient(
                    colors: [Color.tokenWarning.opacity(0.24), Color(red: 115 / 255, green: 42 / 255, blue: 20 / 255).opacity(0.10), Color.clear],
                    center: .bottomTrailing,
                    startRadius: 0,
                    endRadius: 540
                )
                LinearGradient(
                    colors: [Color.clear, Color.black.opacity(0.04), Color.tokenWarning.opacity(0.035)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .marble:
            ZStack {
                RadialGradient(
                    colors: [Color(red: 184 / 255, green: 190 / 255, blue: 190 / 255).opacity(0.12), Color.clear],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 480
                )
                LinearGradient(
                    colors: [Color.white.opacity(0.018), Color.clear, Color.black.opacity(0.13)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }

    @ViewBuilder
    private var motifLayer: some View {
        switch motif {
        case .helmet:
            OdysseyHelmetCrestRelief()
                .opacity(role == .popover ? 0.52 : 0.38)
        case .horse:
            OdysseyTrojanHorseRelief()
                .opacity(role == .share ? 0.55 : 0.34)
        case .marble:
            OdysseyMarbleRelief()
                .opacity(role == .privacy || role == .history ? 0.42 : 0.31)
        }
    }

    private var motifAlignment: Alignment {
        switch motif {
        case .helmet: return .bottomTrailing
        case .horse: return .bottomTrailing
        case .marble: return .trailing
        }
    }
}

struct OdysseySurfaceEmblem: View {
    var role: OdysseySurfaceRole = .generic

    private var motif: OdysseyMotif {
        TokenStepThemeRuntime.odysseyChapter.motif(for: role)
    }

    var body: some View {
        Group {
            switch motif {
            case .helmet:
                OdysseyHelmetCrestRelief()
            case .horse:
                OdysseyTrojanHorseRelief()
            case .marble:
                OdysseyMarbleRelief()
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct OdysseyAtmosphericTexture: View {
    var motif: OdysseyMotif

    var body: some View {
        Canvas { context, size in
            let columns = max(1, Int(size.width / 26))
            let rows = max(1, Int(size.height / 26))
            for column in 0...columns {
                for row in 0...rows where (column * 7 + row * 11) % 9 == 0 {
                    let x = CGFloat(column) * 26 + CGFloat((row * 5) % 11)
                    let y = CGFloat(row) * 26 + CGFloat((column * 3) % 13)
                    let color: Color = motif == .horse
                        ? Color.tokenWarning.opacity((column + row) % 4 == 0 ? 0.16 : 0.045)
                        : Color.tokenInk.opacity(0.03)
                    let diameter: CGFloat = motif == .horse && (column + row) % 4 == 0 ? 1.8 : 1.0
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                        with: .color(color)
                    )
                }
            }

            if motif == .helmet {
                for index in 0..<4 {
                    let y = size.height * (0.26 + CGFloat(index) * 0.13)
                    var mist = Path()
                    mist.move(to: CGPoint(x: -20, y: y))
                    mist.addCurve(
                        to: CGPoint(x: size.width * 0.72, y: y - 8),
                        control1: CGPoint(x: size.width * 0.22, y: y - 18),
                        control2: CGPoint(x: size.width * 0.48, y: y + 14)
                    )
                    context.stroke(mist, with: .color(Color.white.opacity(0.025)), lineWidth: 10)
                }
            }

            if motif == .marble {
                for index in 0..<5 {
                    let startX = size.width * (0.08 + CGFloat(index) * 0.19)
                    var crack = Path()
                    crack.move(to: CGPoint(x: startX, y: 0))
                    crack.addLine(to: CGPoint(x: startX + 18, y: size.height * 0.34))
                    crack.addLine(to: CGPoint(x: startX + 5, y: size.height * 0.52))
                    crack.addLine(to: CGPoint(x: startX + 27, y: size.height))
                    context.stroke(crack, with: .color(Color.white.opacity(0.022)), lineWidth: 0.8)
                }
            }
        }
    }
}

private struct OdysseyHelmetCrestRelief: View {
    var body: some View {
        Canvas { context, size in
            var plume = Path()
            plume.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.54))
            plume.addCurve(
                to: CGPoint(x: size.width * 0.77, y: size.height * 0.22),
                control1: CGPoint(x: size.width * 0.26, y: size.height * 0.08),
                control2: CGPoint(x: size.width * 0.62, y: size.height * 0.04)
            )
            plume.addCurve(
                to: CGPoint(x: size.width * 0.48, y: size.height * 0.42),
                control1: CGPoint(x: size.width * 0.67, y: size.height * 0.25),
                control2: CGPoint(x: size.width * 0.57, y: size.height * 0.34)
            )
            plume.closeSubpath()
            context.fill(plume, with: .color(Color(red: 120 / 255, green: 148 / 255, blue: 163 / 255).opacity(0.28)))

            var shell = Path()
            shell.move(to: CGPoint(x: size.width * 0.28, y: size.height * 0.83))
            shell.addLine(to: CGPoint(x: size.width * 0.30, y: size.height * 0.47))
            shell.addCurve(
                to: CGPoint(x: size.width * 0.78, y: size.height * 0.52),
                control1: CGPoint(x: size.width * 0.43, y: size.height * 0.31),
                control2: CGPoint(x: size.width * 0.68, y: size.height * 0.32)
            )
            shell.addLine(to: CGPoint(x: size.width * 0.63, y: size.height * 0.62))
            shell.addLine(to: CGPoint(x: size.width * 0.56, y: size.height * 0.90))
            shell.addLine(to: CGPoint(x: size.width * 0.43, y: size.height * 0.74))
            shell.closeSubpath()
            context.fill(shell, with: .color(Color(red: 65 / 255, green: 83 / 255, blue: 94 / 255).opacity(0.62)))
            context.stroke(shell, with: .color(Color.tokenGreenDark.opacity(0.54)), lineWidth: 1.6)

            var cheek = Path()
            cheek.move(to: CGPoint(x: size.width * 0.47, y: size.height * 0.53))
            cheek.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * 0.51))
            cheek.addLine(to: CGPoint(x: size.width * 0.57, y: size.height * 0.65))
            context.stroke(cheek, with: .color(Color.tokenGreen.opacity(0.48)), lineWidth: 1.5)

            for index in 0..<9 {
                let progress = CGFloat(index) / 8
                let x = size.width * (0.28 + progress * 0.18)
                let y = size.height * (0.40 + progress * 0.46)
                let width = size.width * (0.065 - progress * 0.018)
                let height = max(5, size.height * 0.027)
                let segment = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height)
                context.fill(Path(roundedRect: segment, cornerRadius: height / 2), with: .color(Color.tokenGreenDark.opacity(0.70)))
                context.stroke(Path(roundedRect: segment, cornerRadius: height / 2), with: .color(Color.tokenGreen.opacity(0.38)), lineWidth: 0.7)
            }
        }
    }
}

private struct OdysseyTrojanHorseRelief: View {
    var body: some View {
        Canvas { context, size in
            let bodyRect = CGRect(
                x: size.width * 0.20,
                y: size.height * 0.42,
                width: size.width * 0.48,
                height: size.height * 0.27
            )
            let body = Path(roundedRect: bodyRect, cornerRadius: size.width * 0.035)
            context.fill(body, with: .color(Color(red: 63 / 255, green: 42 / 255, blue: 28 / 255).opacity(0.74)))
            context.stroke(body, with: .color(Color.tokenGreen.opacity(0.48)), lineWidth: 1.5)

            var neck = Path()
            neck.move(to: CGPoint(x: size.width * 0.59, y: size.height * 0.48))
            neck.addLine(to: CGPoint(x: size.width * 0.68, y: size.height * 0.20))
            neck.addLine(to: CGPoint(x: size.width * 0.82, y: size.height * 0.25))
            neck.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.36))
            neck.addLine(to: CGPoint(x: size.width * 0.69, y: size.height * 0.37))
            neck.addLine(to: CGPoint(x: size.width * 0.66, y: size.height * 0.57))
            neck.closeSubpath()
            context.fill(neck, with: .color(Color(red: 55 / 255, green: 36 / 255, blue: 25 / 255).opacity(0.78)))
            context.stroke(neck, with: .color(Color.tokenGreen.opacity(0.52)), lineWidth: 1.4)

            for x in [0.27, 0.39, 0.55, 0.64] as [CGFloat] {
                let leg = CGRect(
                    x: size.width * x,
                    y: size.height * 0.65,
                    width: size.width * 0.055,
                    height: size.height * 0.25
                )
                context.fill(Path(roundedRect: leg, cornerRadius: 2), with: .color(Color(red: 55 / 255, green: 36 / 255, blue: 25 / 255).opacity(0.82)))
                context.stroke(Path(roundedRect: leg, cornerRadius: 2), with: .color(Color.tokenGreen.opacity(0.32)), lineWidth: 1)
            }

            for index in 1..<6 {
                let y = bodyRect.minY + CGFloat(index) * bodyRect.height / 6
                var plank = Path()
                plank.move(to: CGPoint(x: bodyRect.minX + 6, y: y))
                plank.addLine(to: CGPoint(x: bodyRect.maxX - 5, y: y - 2))
                context.stroke(plank, with: .color(Color.tokenGreenDark.opacity(0.17)), lineWidth: 0.8)
            }

            for index in 0..<6 {
                let y = size.height * (0.19 + CGFloat(index) * 0.043)
                var mane = Path()
                mane.move(to: CGPoint(x: size.width * 0.67, y: y))
                mane.addLine(to: CGPoint(x: size.width * (0.62 - CGFloat(index % 2) * 0.016), y: y + size.height * 0.025))
                context.stroke(mane, with: .color(Color.tokenWarning.opacity(0.55)), lineWidth: 1.5)
            }

            var tail = Path()
            tail.move(to: CGPoint(x: bodyRect.minX, y: bodyRect.minY + 8))
            tail.addCurve(
                to: CGPoint(x: size.width * 0.10, y: size.height * 0.76),
                control1: CGPoint(x: size.width * 0.10, y: size.height * 0.43),
                control2: CGPoint(x: size.width * 0.16, y: size.height * 0.68)
            )
            context.stroke(tail, with: .color(Color.tokenGreen.opacity(0.44)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        }
    }
}

private struct OdysseyMarbleRelief: View {
    var body: some View {
        Canvas { context, size in
            let stone = Color(red: 196 / 255, green: 199 / 255, blue: 195 / 255)
            let headRect = CGRect(
                x: size.width * 0.31,
                y: size.height * 0.12,
                width: size.width * 0.36,
                height: size.height * 0.46
            )
            context.fill(Path(ellipseIn: headRect), with: .color(stone.opacity(0.34)))

            var profile = Path()
            profile.move(to: CGPoint(x: size.width * 0.56, y: size.height * 0.20))
            profile.addCurve(
                to: CGPoint(x: size.width * 0.69, y: size.height * 0.39),
                control1: CGPoint(x: size.width * 0.65, y: size.height * 0.25),
                control2: CGPoint(x: size.width * 0.62, y: size.height * 0.34)
            )
            profile.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.43))
            profile.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.47))
            profile.addCurve(
                to: CGPoint(x: size.width * 0.55, y: size.height * 0.58),
                control1: CGPoint(x: size.width * 0.64, y: size.height * 0.52),
                control2: CGPoint(x: size.width * 0.60, y: size.height * 0.56)
            )
            context.stroke(profile, with: .color(stone.opacity(0.58)), lineWidth: 1.8)

            var shoulders = Path()
            shoulders.move(to: CGPoint(x: size.width * 0.16, y: size.height * 0.91))
            shoulders.addCurve(
                to: CGPoint(x: size.width * 0.84, y: size.height * 0.91),
                control1: CGPoint(x: size.width * 0.23, y: size.height * 0.61),
                control2: CGPoint(x: size.width * 0.76, y: size.height * 0.61)
            )
            shoulders.closeSubpath()
            context.fill(shoulders, with: .color(stone.opacity(0.24)))
            context.stroke(shoulders, with: .color(Color.tokenGreen.opacity(0.25)), lineWidth: 1.2)

            for index in 0..<5 {
                let start = CGPoint(
                    x: size.width * (0.40 + CGFloat(index) * 0.055),
                    y: size.height * (0.20 + CGFloat(index % 2) * 0.11)
                )
                var crack = Path()
                crack.move(to: start)
                crack.addLine(to: CGPoint(x: start.x - 9, y: start.y + size.height * 0.13))
                crack.addLine(to: CGPoint(x: start.x + 4, y: start.y + size.height * 0.23))
                context.stroke(crack, with: .color(Color.black.opacity(0.28)), lineWidth: 0.9)
            }

            context.fill(
                Path(ellipseIn: CGRect(x: size.width * 0.62, y: size.height * 0.33, width: 4, height: 3)),
                with: .color(Color.tokenGreenDark.opacity(0.38))
            )
        }
    }
}

private struct OdysseyGreekKeyBand: View {
    var body: some View {
        Canvas { context, size in
            let unit: CGFloat = 22
            let count = max(1, Int(size.width / unit) + 1)
            for index in 0..<count {
                let x = CGFloat(index) * unit
                var key = Path()
                key.move(to: CGPoint(x: x, y: 2))
                key.addLine(to: CGPoint(x: x + unit - 4, y: 2))
                key.addLine(to: CGPoint(x: x + unit - 4, y: size.height - 3))
                key.addLine(to: CGPoint(x: x + 7, y: size.height - 3))
                key.addLine(to: CGPoint(x: x + 7, y: 7))
                key.addLine(to: CGPoint(x: x + unit - 10, y: 7))
                context.stroke(key, with: .color(Color.tokenGreenDark.opacity(0.42)), lineWidth: 1)
            }
        }
    }
}

struct VoyageWindowFrame: View {
    var inset: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let width = max(0, proxy.size.width - inset * 2)
            let height = max(0, proxy.size.height - inset * 2)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.tokenHairlineStrong, lineWidth: 1)
                    .frame(width: width, height: height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                ForEach(0..<2, id: \.self) { side in
                    let x = side == 0 ? inset : proxy.size.width - inset
                    Path { path in
                        path.move(to: CGPoint(x: x, y: inset + 18))
                        path.addLine(to: CGPoint(x: x, y: proxy.size.height - inset - 18))
                    }
                    .stroke(Color.tokenGreenDark.opacity(0.24), lineWidth: 2)

                    ForEach(0..<4, id: \.self) { index in
                        let y = inset + 24 + CGFloat(index) * max(1, (height - 48) / 3)
                        VoyageRivet()
                            .position(x: x, y: y)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct VoyageCardOrnament: View {
    var cornerRadius: CGFloat = 24

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.tokenInnerHighlight, lineWidth: 1)
                    .padding(1)

                ForEach(Array(corners.enumerated()), id: \.offset) { _, corner in
                    VoyageRivet()
                        .position(
                            x: corner.x == 0 ? 10 : proxy.size.width - 10,
                            y: corner.y == 0 ? 10 : proxy.size.height - 10
                        )
                }

                Path { path in
                    path.move(to: CGPoint(x: 20, y: 1.5))
                    path.addLine(to: CGPoint(x: min(90, proxy.size.width * 0.22), y: 1.5))
                }
                .stroke(Color.tokenGreen.opacity(0.48), lineWidth: 2)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var corners: [CGPoint] {
        [CGPoint(x: 0, y: 0), CGPoint(x: 1, y: 0), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1)]
    }
}

struct VoyageBowRelief: View {
    var body: some View {
        Canvas { context, size in
            var bow = Path()
            bow.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.12))
            bow.addCurve(
                to: CGPoint(x: size.width * 0.18, y: size.height * 0.88),
                control1: CGPoint(x: size.width * 0.90, y: size.height * 0.28),
                control2: CGPoint(x: size.width * 0.90, y: size.height * 0.72)
            )
            context.stroke(
                bow,
                with: .color(Color.tokenGreenDark.opacity(0.32)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

            var string = Path()
            string.move(to: CGPoint(x: size.width * 0.18, y: size.height * 0.12))
            string.addLine(to: CGPoint(x: size.width * 0.36, y: size.height * 0.50))
            string.addLine(to: CGPoint(x: size.width * 0.18, y: size.height * 0.88))
            context.stroke(string, with: .color(Color.tokenGreen.opacity(0.22)), lineWidth: 1)

            var arrow = Path()
            arrow.move(to: CGPoint(x: size.width * 0.05, y: size.height * 0.50))
            arrow.addLine(to: CGPoint(x: size.width * 0.88, y: size.height * 0.50))
            context.stroke(arrow, with: .color(Color.tokenGreenDark.opacity(0.28)), lineWidth: 1.4)

            var head = Path()
            head.move(to: CGPoint(x: size.width * 0.88, y: size.height * 0.50))
            head.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.43))
            head.addLine(to: CGPoint(x: size.width * 0.76, y: size.height * 0.57))
            head.closeSubpath()
            context.fill(head, with: .color(Color.tokenGreenDark.opacity(0.30)))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct VoyageSpearRelief: View {
    var body: some View {
        Canvas { context, size in
            var shaft = Path()
            shaft.move(to: CGPoint(x: size.width * 0.12, y: size.height * 0.86))
            shaft.addLine(to: CGPoint(x: size.width * 0.82, y: size.height * 0.18))
            context.stroke(shaft, with: .color(Color.tokenGreen.opacity(0.22)), lineWidth: 1.6)

            let tip = CGPoint(x: size.width * 0.90, y: size.height * 0.10)
            var head = Path()
            head.move(to: tip)
            head.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * 0.17))
            head.addLine(to: CGPoint(x: size.width * 0.83, y: size.height * 0.28))
            head.closeSubpath()
            context.stroke(
                head,
                with: .color(Color.tokenGreenDark.opacity(0.34)),
                style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct VoyageRivet: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color.tokenGreenDark, Color.tokenGreen.opacity(0.72), Color.black.opacity(0.72)],
                    center: .topLeading,
                    startRadius: 0,
                    endRadius: 4
                )
            )
            .overlay(Circle().stroke(Color.tokenInnerHighlight, lineWidth: 0.7))
            .frame(width: 6, height: 6)
    }
}
