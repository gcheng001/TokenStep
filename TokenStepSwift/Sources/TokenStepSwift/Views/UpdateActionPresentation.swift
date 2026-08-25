import SwiftUI

enum UpdateActionVisualState: Equatable {
    case idle
    case checking
    case upToDate(checkedAt: Date)
    case available(version: String)
    case failed

    static func resolve(
        isCheckingForUpdates: Bool,
        availableUpdate: AvailableUpdate?,
        phase: UpdateCheckPhase
    ) -> UpdateActionVisualState {
        if isCheckingForUpdates || phase == .checking {
            return .checking
        }
        if let availableUpdate {
            return .available(version: availableUpdate.version)
        }
        switch phase {
        case .idle:
            return .idle
        case .checking:
            return .checking
        case let .upToDate(checkedAt):
            return .upToDate(checkedAt: checkedAt)
        case let .available(update, _):
            return .available(version: update.version)
        case .failed:
            return .failed
        }
    }

    var symbol: String {
        switch self {
        case .idle: return "arrow.down.circle"
        case .checking: return "arrow.triangle.2.circlepath"
        case .upToDate: return "checkmark.circle.fill"
        case .available: return "arrow.down.circle.fill"
        case .failed: return "exclamationmark.arrow.circlepath"
        }
    }

    var tint: Color {
        switch self {
        case .idle: return Color.tokenInk.opacity(0.62)
        case .checking: return Color.tokenInk.opacity(0.72)
        case .upToDate: return Color.tokenSuccess
        case .available: return Color.tokenGreenDark
        case .failed: return Color.red.opacity(0.82)
        }
    }

    var help: String {
        switch self {
        case .idle: return L("检查更新")
        case .checking: return L("正在检查更新")
        case let .upToDate(checkedAt):
            return LFormat(
                "当前版本 %@，%@ 已检查，点击重新检查",
                UpdateService.currentVersion,
                Self.timeFormatter.string(from: checkedAt)
            )
        case let .available(version): return LFormat("发现新版本 %@，点击查看", version)
        case .failed: return L("更新检查失败，点击重试")
        }
    }

    var accessibilityLabel: String { help }

    var isChecking: Bool {
        self == .checking
    }

    var isAvailable: Bool {
        if case .available = self { return true }
        return false
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

extension AppState {
    var updateActionVisualState: UpdateActionVisualState {
        UpdateActionVisualState.resolve(
            isCheckingForUpdates: isCheckingForUpdates,
            availableUpdate: availableUpdate,
            phase: updateCheckPhase
        )
    }
}
