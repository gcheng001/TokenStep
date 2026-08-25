import AppKit
import SpriteKit

@main
struct OdysseyMotionPrototypeRender {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared

        let environment = ProcessInfo.processInfo.environment
        let mode = environment[OdysseyMotionPrototypeMode.environmentKey]
            .flatMap(OdysseyMotionPrototypeMode.init(rawValue:))
            ?? .automatic
        guard mode != .off else {
            throw NSError(
                domain: "OdysseyMotionPrototypeRender",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The preview renderer requires automatic or cinematic mode."]
            )
        }

        let outputDirectory = URL(
            fileURLWithPath: environment["TOKENSTEP_ODYSSEY_MOTION_RENDER_DIR"]
                ?? "/tmp/tokenstep-odyssey-motion-preview",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let backgroundImage = environment["TOKENSTEP_ODYSSEY_TROJAN_ART_PATH"]
            .flatMap { NSImage(contentsOfFile: $0) }
            .flatMap(\.cgImageForCurrentRepresentation)

        let canvasSize = CGSize(width: 900, height: 590)
        let scene = OdysseyTrojanParticleScene(size: canvasSize)
        scene.apply(mode: mode)
        scene.setRenderingActive(true)

        let spriteView = SKView(frame: CGRect(origin: .zero, size: canvasSize))
        spriteView.allowsTransparency = true
        spriteView.ignoresSiblingOrder = true
        spriteView.shouldCullNonVisibleNodes = true
        spriteView.presentScene(scene)

        let window = NSWindow(
            contentRect: CGRect(x: -4_000, y: -4_000, width: canvasSize.width, height: canvasSize.height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.contentView = spriteView
        window.orderFront(nil)

        RunLoop.main.run(until: Date().addingTimeInterval(0.20))

        for index in 0..<6 {
            let step = index == 0 ? 0.6 : 1.25
            scene.children.compactMap { $0 as? SKEmitterNode }.forEach {
                $0.advanceSimulationTime(step)
            }
            RunLoop.main.run(until: Date().addingTimeInterval(0.05))

            guard let texture = spriteView.texture(from: scene) else {
                throw NSError(
                    domain: "OdysseyMotionPrototypeRender",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "SpriteKit did not return a preview texture."]
                )
            }
            let image = texture.cgImage()

            let fileName = String(format: "frame-%02d.png", index)
            try writePreview(
                particleImage: image,
                backgroundImage: backgroundImage,
                to: outputDirectory.appendingPathComponent(fileName)
            )
        }

        scene.setRenderingActive(false)
        window.orderOut(nil)
        print("\(mode.rawValue): 6 particle preview frames -> \(outputDirectory.path)")
    }

    private static func writePreview(
        particleImage: CGImage,
        backgroundImage: CGImage?,
        to url: URL
    ) throws {
        let width = particleImage.width
        let height = particleImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else {
            throw NSError(domain: "OdysseyMotionPrototypeRender", code: 3)
        }

        let canvasRect = CGRect(x: 0, y: 0, width: width, height: height)
        if let backgroundImage {
            let scale = max(
                CGFloat(width) / CGFloat(backgroundImage.width),
                CGFloat(height) / CGFloat(backgroundImage.height)
            )
            let backgroundSize = CGSize(
                width: CGFloat(backgroundImage.width) * scale,
                height: CGFloat(backgroundImage.height) * scale
            )
            let backgroundRect = CGRect(
                x: (CGFloat(width) - backgroundSize.width) / 2,
                y: (CGFloat(height) - backgroundSize.height) / 2,
                width: backgroundSize.width,
                height: backgroundSize.height
            )
            context.interpolationQuality = .high
            context.draw(backgroundImage, in: backgroundRect)
        } else {
            context.setFillColor(
                NSColor(calibratedRed: 10 / 255, green: 9 / 255, blue: 8 / 255, alpha: 1).cgColor
            )
            context.fill(canvasRect)
        }
        context.draw(particleImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let composited = context.makeImage(),
              let data = NSBitmapImageRep(cgImage: composited)
                .representation(using: .png, properties: [:])
        else {
            throw NSError(domain: "OdysseyMotionPrototypeRender", code: 4)
        }
        try data.write(to: url, options: .atomic)
    }
}

private extension NSImage {
    var cgImageForCurrentRepresentation: CGImage? {
        var rect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }
}
