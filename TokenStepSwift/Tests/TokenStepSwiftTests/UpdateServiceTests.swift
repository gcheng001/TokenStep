import Foundation
import XCTest
@testable import TokenStepSwift

final class UpdateServiceTests: XCTestCase {
    func testReleaseIsAvailableFromOlderInstalledVersion() throws {
        let result = try UpdateService.evaluateReleaseResponse(
            data: releaseData(tag: "v0.2.4"),
            statusCode: 200,
            currentVersion: "0.2.2"
        )

        guard case let .available(update) = result else {
            return XCTFail("Expected v0.2.4 to be available from v0.2.2")
        }
        XCTAssertEqual(update.version, "0.2.4")
        XCTAssertEqual(update.assetName, "TokenStep-0.2.4.dmg")
        XCTAssertEqual(update.assetSize, 11_312_659)
    }

    func testDevelopmentVersionIsUpToDateAgainstOlderRelease() throws {
        XCTAssertEqual(
            try UpdateService.evaluateReleaseResponse(
                data: releaseData(tag: "v0.2.4"),
                statusCode: 200,
                currentVersion: "0.2.5-dev"
            ),
            .upToDate
        )
    }

    func testDraftAndPrereleaseAreIgnored() throws {
        XCTAssertEqual(
            try UpdateService.evaluateReleaseResponse(
                data: releaseData(tag: "v9.0.0", draft: true),
                statusCode: 200,
                currentVersion: "0.2.2"
            ),
            .upToDate
        )
        XCTAssertEqual(
            try UpdateService.evaluateReleaseResponse(
                data: releaseData(tag: "v9.0.0", prerelease: true),
                statusCode: 200,
                currentVersion: "0.2.2"
            ),
            .upToDate
        )
    }

    func testNewerReleaseWithoutDMGIsRejected() {
        XCTAssertThrowsError(
            try UpdateService.evaluateReleaseResponse(
                data: releaseData(tag: "v0.2.4", assets: []),
                statusCode: 200,
                currentVersion: "0.2.2"
            )
        ) { error in
            XCTAssertEqual(error as? UpdateError, .missingDMG)
        }
    }

    func testInvalidHTTPAndMalformedJSONAreCheckFailures() {
        XCTAssertThrowsError(
            try UpdateService.evaluateReleaseResponse(
                data: releaseData(tag: "v0.2.4"),
                statusCode: 503,
                currentVersion: "0.2.2"
            )
        ) { error in
            XCTAssertEqual(error as? UpdateError, .checkFailed)
        }

        XCTAssertThrowsError(
            try UpdateService.evaluateReleaseResponse(
                data: Data("not-json".utf8),
                statusCode: 200,
                currentVersion: "0.2.2"
            )
        ) { error in
            XCTAssertEqual(error as? UpdateError, .checkFailed)
        }
    }

    func testInvalidReleaseOrInstalledVersionIsRejected() {
        XCTAssertThrowsError(
            try UpdateService.evaluateReleaseResponse(
                data: releaseData(tag: "not-a-version"),
                statusCode: 200,
                currentVersion: "0.2.2"
            )
        ) { error in
            XCTAssertEqual(error as? UpdateError, .checkFailed)
        }
        XCTAssertThrowsError(
            try UpdateService.evaluateReleaseResponse(
                data: releaseData(tag: "v0.2.4"),
                statusCode: 200,
                currentVersion: "development"
            )
        ) { error in
            XCTAssertEqual(error as? UpdateError, .checkFailed)
        }
    }

    func testManualPolicyBypassesToggleAndAutomaticThrottleAndSkippedVersion() {
        let now = Date(timeIntervalSince1970: 100_000)
        XCTAssertTrue(
            UpdateCheckPolicy.shouldStart(
                trigger: .manual,
                autoUpdateEnabled: false,
                lastAttemptAt: now.addingTimeInterval(-10),
                now: now
            )
        )
        XCTAssertTrue(
            UpdateCheckPolicy.shouldStart(
                trigger: .manual,
                autoUpdateEnabled: false,
                lastAttemptAt: now.addingTimeInterval(-9),
                now: now
            )
        )

        let update = makeUpdate(version: "0.2.4")
        XCTAssertEqual(
            UpdateCheckPolicy.visibleUpdate(
                from: .available(update),
                skippedVersion: "0.2.4",
                trigger: .manual
            ),
            update
        )
    }

    func testManualAvailableUpdateRequestsImmediateWindowPresentation() {
        let update = makeUpdate(version: "0.2.6")

        XCTAssertTrue(
            UpdatePresentationPolicy.shouldPresentWindow(
                trigger: .manual,
                update: update
            )
        )
        XCTAssertFalse(
            UpdatePresentationPolicy.shouldPresentWindow(
                trigger: .manual,
                update: nil
            )
        )
        XCTAssertFalse(
            UpdatePresentationPolicy.shouldPresentWindow(
                trigger: .startup,
                update: update
            )
        )
        XCTAssertFalse(
            UpdatePresentationPolicy.shouldPresentWindow(
                trigger: .timer,
                update: update
            )
        )
    }

    func testAutomaticCheckHonorsToggleSixHourThrottleAndSkippedVersion() {
        let now = Date(timeIntervalSince1970: 100_000)
        XCTAssertFalse(
            UpdateCheckPolicy.shouldStart(
                trigger: .foreground,
                autoUpdateEnabled: false,
                lastAttemptAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            UpdateCheckPolicy.shouldStart(
                trigger: .foreground,
                autoUpdateEnabled: true,
                lastAttemptAt: now.addingTimeInterval(-(6 * 60 * 60 - 1)),
                now: now
            )
        )
        XCTAssertTrue(
            UpdateCheckPolicy.shouldStart(
                trigger: .foreground,
                autoUpdateEnabled: true,
                lastAttemptAt: now.addingTimeInterval(-(6 * 60 * 60)),
                now: now
            )
        )
        XCTAssertFalse(
            UpdateCheckPolicy.shouldStart(
                trigger: .startup,
                autoUpdateEnabled: true,
                lastAttemptAt: now,
                now: now
            )
        )
        XCTAssertTrue(
            UpdateCheckPolicy.shouldStart(
                trigger: .startup,
                autoUpdateEnabled: true,
                lastAttemptAt: nil,
                now: now
            )
        )
        XCTAssertFalse(
            UpdateCheckPolicy.shouldStart(
                trigger: .foreground,
                autoUpdateEnabled: true,
                lastAttemptAt: nil,
                now: now,
                startupCheckPending: true
            )
        )

        XCTAssertNil(
            UpdateCheckPolicy.visibleUpdate(
                from: .available(makeUpdate(version: "0.2.4")),
                skippedVersion: "0.2.4",
                trigger: .timer
            )
        )
    }

    func testGateSuppressesConcurrentChecksAndReopensAfterCompletion() {
        let now = Date(timeIntervalSince1970: 100_000)
        var gate = UpdateCheckGate()

        XCTAssertTrue(
            gate.begin(
                trigger: .manual,
                autoUpdateEnabled: false,
                now: now
            )
        )
        XCTAssertFalse(
            gate.begin(
                trigger: .manual,
                autoUpdateEnabled: false,
                now: now.addingTimeInterval(1)
            )
        )
        gate.finish()
        XCTAssertFalse(
            gate.begin(
                trigger: .manual,
                autoUpdateEnabled: false,
                now: now.addingTimeInterval(2)
            )
        )
        XCTAssertTrue(
            gate.begin(
                trigger: .manual,
                autoUpdateEnabled: false,
                now: now.addingTimeInterval(10)
            )
        )
    }

    func testRecentAutomaticCheckDoesNotBlockManualCheck() {
        let now = Date(timeIntervalSince1970: 100_000)
        var gate = UpdateCheckGate()
        XCTAssertTrue(
            gate.begin(
                trigger: .startup,
                autoUpdateEnabled: true,
                now: now
            )
        )
        gate.finish()
        XCTAssertTrue(
            gate.begin(
                trigger: .manual,
                autoUpdateEnabled: true,
                now: now.addingTimeInterval(1)
            )
        )
    }

    func testFallbackLatestRedirectBuildsVersionedDMGWithoutGitHubAPI() throws {
        let result = try UpdateService.evaluateFallbackReleaseResponse(
            responseURL: URL(string: "https://github.com/Backtthefuture/TokenStep/releases/tag/v0.2.7"),
            statusCode: 200,
            currentVersion: "0.2.6"
        )

        guard case let .available(update) = result else {
            return XCTFail("Expected fallback release to be available")
        }
        XCTAssertEqual(update.version, "0.2.7")
        XCTAssertEqual(update.assetName, "TokenStep-0.2.7.dmg")
        XCTAssertEqual(
            update.assetURL.absoluteString,
            "https://github.com/Backtthefuture/TokenStep/releases/download/v0.2.7/TokenStep-0.2.7.dmg"
        )
        XCTAssertEqual(update.formattedSize, L("发布包"))
    }

    func testFallbackLatestRedirectRejectsUnresolvedLatestPage() {
        XCTAssertThrowsError(
            try UpdateService.evaluateFallbackReleaseResponse(
                responseURL: URL(string: "https://github.com/Backtthefuture/TokenStep/releases/latest"),
                statusCode: 200,
                currentVersion: "0.2.6"
            )
        ) { error in
            XCTAssertEqual(error as? UpdateError, .checkFailed)
        }
    }

    func testRateLimitedAPIUsesNonAPIFallback() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UpdateMockURLProtocol.self]
        let session = URLSession(configuration: configuration)
        UpdateMockURLProtocol.handler = { request in
            if request.url?.host == "api.example.com" {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 403,
                    httpVersion: nil,
                    headerFields: [
                        "X-RateLimit-Remaining": "0",
                        "X-RateLimit-Reset": "100000"
                    ]
                )!
                return (response, Data())
            }

            let resolvedURL = URL(string: "https://github.com/Backtthefuture/TokenStep/releases/tag/v0.2.7")!
            let response = HTTPURLResponse(
                url: resolvedURL,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "text/html"]
            )!
            return (response, Data())
        }
        defer { UpdateMockURLProtocol.handler = nil }

        let result = try await UpdateService.checkForUpdates(
            currentVersion: "0.2.6",
            session: session,
            releaseURL: URL(string: "https://api.example.com/releases/latest")!,
            fallbackURL: URL(string: "https://www.example.com/releases/latest")!
        )

        guard case let .available(update) = result else {
            return XCTFail("Expected fallback update")
        }
        XCTAssertEqual(update.version, "0.2.7")
    }

    func testRateLimitErrorExplainsRecoveryTime() {
        let reset = Date(timeIntervalSince1970: 100_000)
        let message = UpdateError.rateLimited(resetAt: reset).localizedDescription
        XCTAssertTrue(message.contains("GitHub"))
        XCTAssertTrue(message.contains(":"))
    }

    private func releaseData(
        tag: String,
        draft: Bool = false,
        prerelease: Bool = false,
        assets: [[String: Any]]? = nil
    ) -> Data {
        let defaultAssets: [[String: Any]] = [
            [
                "name": "TokenStep-\(tag.strippingLeadingV).dmg",
                "browser_download_url": "https://example.com/TokenStep.dmg",
                "size": 11_312_659
            ]
        ]
        let object: [String: Any] = [
            "tag_name": tag,
            "name": "TokenStep \(tag)",
            "body": "Release notes",
            "draft": draft,
            "prerelease": prerelease,
            "html_url": "https://github.com/Backtthefuture/TokenStep/releases/tag/\(tag)",
            "assets": assets ?? defaultAssets
        ]
        return try! JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private func makeUpdate(version: String) -> AvailableUpdate {
        AvailableUpdate(
            version: version,
            tagName: "v\(version)",
            title: "TokenStep \(version)",
            notes: "",
            pageURL: URL(string: "https://example.com/release")!,
            assetURL: URL(string: "https://example.com/app.dmg")!,
            assetName: "TokenStep.dmg",
            assetSize: 1
        )
    }
}

private extension String {
    var strippingLeadingV: String {
        hasPrefix("v") ? String(dropFirst()) : self
    }
}

private final class UpdateMockURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: UpdateError.checkFailed)
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
