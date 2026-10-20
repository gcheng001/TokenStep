import Foundation

enum QuotaRefreshCoordinator {
    /// `bypassCache` skips provider file caches, for a refresh the user asked for.
    static func fetch(providers: Set<QuotaProviderID>, bypassCache: Bool = false) -> [QuotaProviderID: ProviderQuota] {
        var result: [QuotaProviderID: ProviderQuota] = [:]
        let lock = NSLock()
        let group = DispatchGroup()
        for provider in providers {
            group.enter()
            DispatchQueue.global(qos: .utility).async {
                let quota = read(provider, bypassCache: bypassCache)
                lock.lock()
                result[provider] = quota
                lock.unlock()
                group.leave()
            }
        }
        _ = group.wait(timeout: .now() + 12)
        // Providers that missed the deadline keep running and may still write;
        // snapshot under the same lock so the read never races those writes.
        lock.lock()
        defer { lock.unlock() }
        return result
    }

    static func read(_ provider: QuotaProviderID, bypassCache: Bool = false) -> ProviderQuota {
        do {
            let quota: ProviderQuota
            switch provider {
            case .codex:
                quota = try CodexQuotaService.read().asProviderQuota(.codex)
            case .claude:
                return try ClaudeQuotaService.read(useCache: !bypassCache).asProviderQuota(.claude)
            case .cursor:
                return try CursorQuotaService.read(useCache: !bypassCache)
            case .glm:
                quota = try GLMQuotaService.read()
            case .kimi:
                quota = try KimiQuotaService.read()
            case .grok:
                quota = try GrokQuotaService.read()
            }
            return quota
        } catch {
            return ProviderQuota.unavailable(
                provider,
                status: status(for: provider, error: error),
                message: error.localizedDescription
            )
        }
    }

    private static func status(for provider: QuotaProviderID, error: Error) -> QuotaStatus {
        let text = error.localizedDescription
        if text.contains("未登录") {
            return .notLoggedIn
        }
        if text.contains("非订阅") || text.contains("按量") {
            return .wrongKeyType
        }
        if text.contains("grok login") || text.contains("需要") && provider == .grok {
            return .needsLogin
        }
        return .unavailable
    }
}
