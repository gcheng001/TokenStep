import AppKit
import SwiftUI

@main
struct PopoverPanelRender {
    @MainActor
    static func main() throws {
        _ = NSApplication.shared
        try validateIsolatedAppSupport()
        try seedEmptyAppSupport()
        if let iconPath = ProcessInfo.processInfo.environment["TOKENSTEP_ICON_PATH"],
           let icon = NSImage(contentsOfFile: iconPath) {
            NSApp.applicationIconImage = icon
        }

        let theme = ProcessInfo.processInfo.environment["TOKENSTEP_POPOVER_THEME"] == "voyage"
            ? TokenStepTheme.voyage
            : TokenStepTheme.green
        let chapter = ProcessInfo.processInfo.environment["TOKENSTEP_ODYSSEY_CHAPTER"]
            .flatMap(TokenStepOdysseyChapter.init(rawValue:))
            ?? .aegeanMist
        let showsRank = ProcessInfo.processInfo.environment["TOKENSTEP_POPOVER_RANK"] != "hidden"
        let rank = fixtureRank()
        let appState = AppState()
        appState.installRenderFixture(
            snapshot: fixtureSnapshot(),
            settings: fixtureSettings(theme: theme, chapter: chapter, showsRank: showsRank),
            quotas: fixtureQuotas(),
            tokenRank: showsRank ? rank.leaderboard : nil,
            agentWorkRankIdentity: showsRank ? rank.identity : nil
        )

        let output = URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["TOKENSTEP_POPOVER_RENDER_PATH"]
                ?? "/tmp/tokenstep-popover-v0.2.4.png"
        )
        try FileManager.default.createDirectory(
            at: output.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let content = PopoverPanelView()
            .environmentObject(appState)
            .environment(\.colorScheme, theme.colorScheme)
            .environment(\.isScreenshotRendering, true)
            .fixedSize(horizontal: false, vertical: true)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let image = renderer.nsImage,
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:])
        else {
            throw NSError(domain: "PopoverPanelRender", code: 1)
        }
        try png.write(to: output, options: .atomic)
        guard bitmap.pixelsWide == 1_800, bitmap.pixelsHigh >= 600 else {
            throw NSError(domain: "PopoverPanelRender", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Unexpected render size: \(bitmap.pixelsWide)x\(bitmap.pixelsHigh)"
            ])
        }
        print("v0.2.4-horizontal: \(bitmap.pixelsWide)x\(bitmap.pixelsHigh) -> \(output.path)")
    }

    private static func validateIsolatedAppSupport() throws {
        guard let override = ProcessInfo.processInfo.environment["TOKENSTEP_TEST_APP_SUPPORT_ROOT"],
              !override.isEmpty
        else {
            throw NSError(domain: "PopoverPanelRender", code: 3)
        }
        let expected = URL(fileURLWithPath: override, isDirectory: true).standardizedFileURL
        guard AppPaths.appSupportRoot.standardizedFileURL == expected else {
            throw NSError(domain: "PopoverPanelRender", code: 4)
        }
    }

    @MainActor
    private static func seedEmptyAppSupport() throws {
        try writeJSON(UsageSnapshot.empty, to: AppPaths.usageJSON)
        try writeJSON(TokenStepSettings.defaults, to: AppPaths.settingsJSON)
    }

    private static func fixtureSnapshot() -> UsageSnapshot {
        let today = DateFormatter.tokenStepDay.string(from: Date())
        let total = 428_000_000
        let daily = DailyUsage(
            date: today,
            tools: ["Codex": 320_000_000, "Claude Code": 82_000_000, "Cursor": 26_000_000],
            models: ["gpt-5.2-codex": 310_000_000, "claude-opus-4.1": 82_000_000, "gemini-2.5-pro": 36_000_000],
            modelCosts: ["gpt-5.2-codex": 15.8, "claude-opus-4.1": 6.7, "gemini-2.5-pro": 1.4],
            totalTokens: total,
            cost: 23.9
        )
        let work = DailyAgentWork(
            date: today,
            totalTokens: total,
            activeHours: 8,
            modelRequestCount: 824,
            toolCallCount: 312,
            sources: [
                AgentWorkSource(source: "Codex", tokens: 320_000_000, modelRequestCount: 612, toolCallCount: 228),
                AgentWorkSource(source: "Claude Code", tokens: 82_000_000, modelRequestCount: 156, toolCallCount: 66),
                AgentWorkSource(source: "Cursor", tokens: 26_000_000, modelRequestCount: 56, toolCallCount: 18)
            ],
            inputTokens: 420_000_000,
            cachedInputTokens: 302_000_000,
            outputTokens: 8_000_000,
            cacheCoverageComplete: true
        )
        return UsageSnapshot(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            timezone: "Asia/Shanghai",
            totals: UsageTotals(tokens: total, cost: 23.9, activeDays: 58),
            daily: [daily],
            agentWork: [work],
            tools: [],
            models: [],
            sources: [:]
        )
    }

    private static func fixtureSettings(
        theme: TokenStepTheme,
        chapter: TokenStepOdysseyChapter,
        showsRank: Bool
    ) -> TokenStepSettings {
        TokenStepSettings(
            dailyGoalTokens: 1_000_000_000,
            refreshIntervalSeconds: 300,
            historyDays: 180,
            theme: theme,
            autoUpdateEnabled: false,
            askBeforeDownloadingUpdates: true,
            requireVerifiedUpdates: true,
            tokenIslandEnabled: false,
            tokenIslandPlacement: .menuBar,
            enabledQuotaProviders: [.codex, .claude, .cursor],
            cursorQuotaEnabled: true,
            cursorCodeSignalEnabled: false,
            agentWorkRankVisibility: showsRank ? .visible : .hidden,
            showExperimentalAgentSources: true,
            language: .zhHans,
            skippedUpdateVersion: nil,
            classicTheme: .green,
            odysseyChapter: chapter
        )
    }

    private static func fixtureRank() -> (leaderboard: TokenRankLeaderboard, identity: AgentWorkRankIdentity) {
        let identity = AgentWorkRankIdentity(
            id: 42,
            name: "Agent 黄叔",
            avatarURL: nil,
            lastSyncedAt: Date()
        )
        let entry = TokenRankEntry(
            rank: 1,
            userID: identity.id,
            name: identity.name,
            avatarURL: nil,
            totalTokens: 6_932_000_000,
            callCount: 8_124,
            sessionCount: 286,
            clients: ["codex": 6_570_000_000, "cursor": 362_000_000],
            models: ["gpt-5.2-codex": 5_800_000_000]
        )
        return (
            TokenRankLeaderboard(
                fetchedAt: Date().addingTimeInterval(-9 * 60),
                range: "today",
                client: "all",
                usageMode: "total_token_usage",
                totalTokens: 20_971_000_000,
                totalRankedUsers: 105,
                topLimit: 100,
                entries: [entry]
            ),
            identity
        )
    }

    private static func fixtureQuotas() -> [QuotaProviderID: ProviderQuota] {
        let now = Date()
        return [
            .codex: ProviderQuota(
                provider: .codex,
                windows: [
                    QuotaWindow(kind: .fiveHour, usedPercent: 18, remaining: 82, total: 100, resetsAt: now.addingTimeInterval(7_200)),
                    QuotaWindow(kind: .sevenDay, usedPercent: 36, remaining: 64, total: 100, resetsAt: now.addingTimeInterval(259_200))
                ],
                status: .available,
                fetchedAt: now,
                message: nil
            ),
            .claude: ProviderQuota(
                provider: .claude,
                windows: [
                    QuotaWindow(kind: .fiveHour, usedPercent: 41, remaining: 59, total: 100, resetsAt: now.addingTimeInterval(9_000)),
                    QuotaWindow(kind: .sevenDay, usedPercent: 24, remaining: 76, total: 100, resetsAt: now.addingTimeInterval(345_600))
                ],
                status: .available,
                fetchedAt: now,
                message: nil
            ),
            .cursor: ProviderQuota(
                provider: .cursor,
                windows: [
                    QuotaWindow(kind: .cursorModels, usedPercent: 67, remaining: 33, total: 100, resetsAt: now.addingTimeInterval(172_800)),
                    QuotaWindow(kind: .otherModels, usedPercent: 12, remaining: 88, total: 100, resetsAt: now.addingTimeInterval(172_800))
                ],
                status: .available,
                fetchedAt: now,
                message: nil
            )
        ]
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
