import Foundation
import XCTest
@testable import TokenStepSwift

final class SettingsMigrationTests: XCTestCase {
    func testVersion023DefaultsToVoyageTheme() {
        XCTAssertEqual(TokenStepSettings.defaults.theme, .voyage)
    }

    func testVersion024DefaultsToOdysseyDirectorsCutAndRemembersClassicGreen() {
        let settings = TokenStepSettings.defaults
        XCTAssertEqual(settings.themePack, .odyssey)
        XCTAssertEqual(settings.odysseyChapter, .directorsCut)
        XCTAssertEqual(settings.classicTheme, .green)
    }

    func testVersion023VoyageSettingsDecodeIntoVersion024ThemePack() throws {
        let json = """
        {"theme": "voyage"}
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(TokenStepSettings.self, from: json)

        XCTAssertEqual(settings.themePack, .odyssey)
        XCTAssertEqual(settings.odysseyChapter, .directorsCut)
        XCTAssertEqual(settings.classicTheme, .green)
    }

    func testLegacyClassicThemeBecomesRememberedClassicPalette() throws {
        let json = """
        {"theme": "ocean"}
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(TokenStepSettings.self, from: json)

        XCTAssertEqual(settings.themePack, .classic)
        XCTAssertEqual(settings.classicTheme, .ocean)
    }

    func testVersion023MigratesSavedLegacyThemeToVoyageOnce() {
        var settings = TokenStepSettings.defaults
        settings.theme = .green
        settings.dailyGoalTokens = 321_000_000

        let migrated = DataService.applyingVoyageThemeMigration(
            settings,
            markerExists: false
        )

        XCTAssertEqual(migrated.theme, .voyage)
        XCTAssertEqual(migrated.dailyGoalTokens, 321_000_000)
    }

    func testVersion023MigrationMarkerPreservesLaterThemeChoice() {
        var settings = TokenStepSettings.defaults
        settings.theme = .green

        let migrated = DataService.applyingVoyageThemeMigration(
            settings,
            markerExists: true
        )

        XCTAssertEqual(migrated.theme, .green)
    }

    func testLegacyShowCodexQuotaTrueMigratesToCodexAndClaude() throws {
        let json = """
        {"show_codex_quota": true}
        """.data(using: .utf8)!
        let settings = try JSONDecoder().decode(TokenStepSettings.self, from: json)
        XCTAssertEqual(settings.enabledQuotaProviders, [.codex, .claude])
        XCTAssertTrue(settings.showCodexQuota)
        XCTAssertFalse(settings.cursorQuotaEnabled)
        XCTAssertFalse(settings.cursorCodeSignalEnabled)
    }

    func testLegacyShowCodexQuotaFalseMigratesToEmptySet() throws {
        let json = """
        {"show_codex_quota": false}
        """.data(using: .utf8)!
        let settings = try JSONDecoder().decode(TokenStepSettings.self, from: json)
        XCTAssertTrue(settings.enabledQuotaProviders.isEmpty)
        XCTAssertFalse(settings.showCodexQuota)
    }

    func testRoundTripKeepsNewFields() throws {
        var settings = TokenStepSettings.defaults
        settings.enabledQuotaProviders = [.codex, .cursor, .glm]
        settings.cursorQuotaEnabled = true
        settings.cursorCodeSignalEnabled = true
        settings.historyDays = 90
        settings.theme = .voyage
        settings.classicTheme = .amber
        settings.odysseyChapter = .ashMarble
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(TokenStepSettings.self, from: data)
        XCTAssertEqual(decoded.enabledQuotaProviders, [.codex, .cursor, .glm])
        XCTAssertTrue(decoded.cursorQuotaEnabled)
        XCTAssertTrue(decoded.cursorCodeSignalEnabled)
        XCTAssertEqual(decoded.historyDays, 90)
        XCTAssertTrue(decoded.showCodexQuota)
        XCTAssertEqual(decoded.themePack, .odyssey)
        XCTAssertEqual(decoded.classicTheme, .amber)
        XCTAssertEqual(decoded.odysseyChapter, .ashMarble)
    }

    func testCursorFlagStaysInSyncWithProviderSet() {
        var settings = TokenStepSettings.defaults
        settings.setQuotaProvider(.cursor, enabled: true)
        XCTAssertTrue(settings.cursorQuotaEnabled)
        XCTAssertTrue(settings.enabledQuotaProviders.contains(.cursor))
        settings.setQuotaProvider(.cursor, enabled: false)
        XCTAssertFalse(settings.cursorQuotaEnabled)
        XCTAssertFalse(settings.enabledQuotaProviders.contains(.cursor))
    }
}
