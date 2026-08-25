import AppKit
import SwiftUI

@main
struct MainWindowUpdateStateRender {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared
        try validateIsolatedAppSupport()
        try seedEmptyAppSupport()
        if let iconPath = ProcessInfo.processInfo.environment["TOKENSTEP_ICON_PATH"],
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }

        let theme: TokenStepTheme = ProcessInfo.processInfo.environment["TOKENSTEP_UPDATE_RENDER_THEME"] == "classic"
            ? .green
            : .voyage
        let language = ProcessInfo.processInfo.environment["TOKENSTEP_UPDATE_RENDER_LANGUAGE"]
            .flatMap(TokenStepLanguage.init(rawValue:))
            ?? .zhHans
        let stateName = ProcessInfo.processInfo.environment["TOKENSTEP_UPDATE_RENDER_STATE"] ?? "idle"
        let settings = fixtureSettings(theme: theme, language: language)
        let update = fixtureUpdate()
        let phase = fixturePhase(stateName, update: update)
        let appState = AppState()
        appState.installRenderFixture(
            snapshot: fixtureSnapshot(),
            settings: settings,
            updateCheckPhase: phase,
            availableUpdate: stateName == "available" ? update : nil
        )

        let content = MainWindowView(navigation: MainWindowNavigation(section: .today))
            .environmentObject(appState)
            .environment(\.colorScheme, settings.theme.colorScheme)
            .environment(\.isScreenshotRendering, true)
            .frame(width: 1_000, height: 740)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            throw NSError(domain: "MainWindowUpdateStateRender", code: 1)
        }

        let output = URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["TOKENSTEP_UPDATE_RENDER_PATH"]
                ?? "/tmp/tokenstep-update-state.png"
        )
        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try png.write(to: output, options: .atomic)
        guard bitmap.pixelsWide == 2_000, bitmap.pixelsHigh == 1_480 else {
            throw NSError(domain: "MainWindowUpdateStateRender", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Unexpected render size: \(bitmap.pixelsWide)x\(bitmap.pixelsHigh)"
            ])
        }
        print("update-\(stateName): \(bitmap.pixelsWide)x\(bitmap.pixelsHigh) -> \(output.path)")
    }

    private static func fixturePhase(
        _ state: String,
        update: AvailableUpdate
    ) -> UpdateCheckPhase {
        let checkedAt = Date(timeIntervalSince1970: 1_787_628_600)
        switch state {
        case "checking": return .checking
        case "up-to-date": return .upToDate(checkedAt: checkedAt)
        case "available": return .available(update, checkedAt: checkedAt)
        case "failed": return .failed(checkedAt: checkedAt, message: L("检查更新失败，请稍后再试。"))
        default: return .idle
        }
    }

    private static func fixtureSnapshot() -> UsageSnapshot {
        let today = DateFormatter.tokenStepDay.string(from: Date())
        let usage = DailyUsage(
            date: today,
            tools: ["Codex": 42_000_000, "Cursor": 8_000_000],
            models: ["gpt-5.2-codex": 42_000_000, "gemini-2.5-pro": 8_000_000],
            totalTokens: 50_000_000,
            cost: 4.2
        )
        return UsageSnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            timezone: "Asia/Shanghai",
            totals: UsageTotals(tokens: 50_000_000, cost: 4.2, activeDays: 1),
            daily: [usage],
            agentWork: [],
            tools: [],
            models: [],
            sources: [:]
        )
    }

    private static func fixtureSettings(
        theme: TokenStepTheme,
        language: TokenStepLanguage
    ) -> TokenStepSettings {
        TokenStepSettings(
            dailyGoalTokens: 100_000_000,
            refreshIntervalSeconds: 0,
            historyDays: 30,
            theme: theme,
            autoUpdateEnabled: false,
            askBeforeDownloadingUpdates: true,
            requireVerifiedUpdates: true,
            tokenIslandEnabled: false,
            tokenIslandPlacement: .menuBar,
            enabledQuotaProviders: [],
            cursorQuotaEnabled: false,
            cursorCodeSignalEnabled: false,
            agentWorkRankVisibility: .hidden,
            showExperimentalAgentSources: true,
            language: language,
            skippedUpdateVersion: nil,
            classicTheme: .green,
            odysseyChapter: .trojanInferno
        )
    }

    private static func fixtureUpdate() -> AvailableUpdate {
        AvailableUpdate(
            version: "0.2.6",
            tagName: "v0.2.6",
            title: "TokenStep 0.2.6",
            notes: "Update fixture",
            pageURL: URL(string: "https://example.com/release")!,
            assetURL: URL(string: "https://example.com/TokenStep.dmg")!,
            assetName: "TokenStep-0.2.6.dmg",
            assetSize: 12_000_000
        )
    }

    private static func validateIsolatedAppSupport() throws {
        guard let override = ProcessInfo.processInfo.environment["TOKENSTEP_TEST_APP_SUPPORT_ROOT"],
              !override.isEmpty
        else {
            throw NSError(domain: "MainWindowUpdateStateRender", code: 3)
        }
        let expected = URL(fileURLWithPath: override, isDirectory: true).standardizedFileURL
        guard AppPaths.appSupportRoot.standardizedFileURL == expected else {
            throw NSError(domain: "MainWindowUpdateStateRender", code: 4)
        }
    }

    @MainActor
    private static func seedEmptyAppSupport() throws {
        try writeJSON(UsageSnapshot.empty, to: AppPaths.usageJSON)
        try writeJSON(TokenStepSettings.defaults, to: AppPaths.settingsJSON)
    }

    private static func writeJSON<T: Encodable>(_ value: T, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: url, options: .atomic)
    }
}
