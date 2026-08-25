import SwiftUI

struct SettingsGeneralPane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                SettingsSectionCard(title: L("每日目标"), subtitle: L("一圈等于多少 Token")) {
                    HStack(spacing: 10) {
                        GoalStepButton(symbol: "minus") {
                            appState.setGoal(appState.settings.dailyGoalTokens - 10_000_000)
                        }
                        .disabled(appState.settings.dailyGoalTokens <= 10_000_000)
                        Text(TokenStepFormat.tokens(appState.settings.dailyGoalTokens, compact: true))
                            .font(.system(size: 27, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.tokenInk)
                            .monospacedDigit()
                            .frame(minWidth: 72)
                        GoalStepButton(symbol: "plus") {
                            appState.setGoal(appState.settings.dailyGoalTokens + 10_000_000)
                        }
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach([50_000_000, 100_000_000, 200_000_000], id: \.self) { value in
                                SettingsPickerChip(
                                    title: TokenStepFormat.tokens(value, compact: true),
                                    selected: appState.settings.dailyGoalTokens == value
                                ) {
                                    appState.setGoal(value)
                                }
                            }
                        }
                    }
                }

                SettingsSectionCard(
                    title: L("历史范围"),
                    subtitle: L("采集与图表回溯天数（7–365）"),
                    badge: L("本版新增入口"),
                    badgeStyle: .ok
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 5) {
                            ForEach([90, 180, 365], id: \.self) { days in
                                SettingsPickerChip(
                                    title: "\(days)",
                                    selected: appState.settings.historyDays == days
                                ) {
                                    appState.setHistoryDays(days)
                                }
                            }
                            SettingsPickerChip(
                                title: "30",
                                selected: appState.settings.historyDays == 30
                            ) {
                                appState.setHistoryDays(30)
                            }
                        }
                        Text(L("调大会增加首次采集耗时。"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            SettingsSectionCard(
                title: L("主题皮肤包"),
                subtitle: L("经典配色与奥德赛视觉篇章可随时切换")
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        ForEach(TokenStepThemePack.allCases) { pack in
                            ThemePackOptionButton(
                                pack: pack,
                                selected: appState.settings.themePack == pack,
                                classicTheme: appState.settings.classicTheme,
                                odysseyChapter: appState.settings.odysseyChapter
                            ) {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    appState.setThemePack(pack)
                                }
                            }
                        }
                    }

                    Rectangle()
                        .fill(Color.tokenDivider)
                        .frame(height: 1)

                    if appState.settings.themePack == .odyssey {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(L("奥德赛视觉篇章"))
                                        .font(.callout.weight(.heavy))
                                        .foregroundStyle(Color.tokenInk)
                                    Text(L("导演剪辑会为不同界面自动分配冷雾、火海与灰烬。"))
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(appState.settings.odysseyChapter.title)
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(Color.tokenGreenDark)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 5)
                                    .background(Color.tokenGreen.opacity(0.12), in: Capsule())
                                    .overlay(Capsule().stroke(Color.tokenHairlineStrong))
                            }

                            HStack(spacing: 8) {
                                ForEach(TokenStepOdysseyChapter.allCases) { chapter in
                                    OdysseyChapterButton(
                                        chapter: chapter,
                                        selected: appState.settings.odysseyChapter == chapter
                                    ) {
                                        withAnimation(.easeOut(duration: 0.18)) {
                                            appState.setOdysseyChapter(chapter)
                                        }
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(L("经典主题色"))
                                    .font(.callout.weight(.heavy))
                                    .foregroundStyle(Color.tokenInk)
                                Text(L("原版 TokenStep 的五种明亮配色"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                ForEach(TokenStepTheme.classicCases) { theme in
                                    Button {
                                        appState.setClassicTheme(theme)
                                    } label: {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    colors: [theme.palette.accentSoft.color, theme.palette.accent.color],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 27, height: 27)
                                            .overlay(
                                                Circle().stroke(
                                                    theme == appState.settings.classicTheme ? Color.tokenInk : Color.clear,
                                                    lineWidth: 2
                                                )
                                            )
                                            .overlay {
                                                if theme == appState.settings.classicTheme {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 10, weight: .black))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                    }
                                    .buttonStyle(.plain)
                                    .help(theme.title)
                                }
                            }
                        }
                        .padding(.vertical, 7)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }

            HStack(alignment: .top, spacing: 12) {
                SettingsSectionCard(title: L("语言"), subtitle: L("选择 TokenStep 的显示语言")) {
                    HStack {
                        Text(L("语言"))
                            .font(.callout.weight(.semibold))
                        Spacer()
                        HStack(spacing: 5) {
                            ForEach(TokenStepLanguage.allCases) { language in
                                SettingsPickerChip(
                                    title: language.compactTitle,
                                    selected: appState.settings.language == language
                                ) {
                                    appState.setLanguage(language)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 9)
                }

                SettingsSectionCard(title: L("显示位置"), subtitle: L("菜单栏或灵动岛，二选一")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L("位置"))
                                .font(.callout.weight(.semibold))
                            Spacer()
                            HStack(spacing: 5) {
                                ForEach(TokenIslandDisplayPlacement.allCases) { placement in
                                    SettingsPickerChip(
                                        title: placement.shortTitle,
                                        selected: appState.settings.tokenIslandPlacement == placement
                                    ) {
                                        appState.setTokenIslandPlacement(placement)
                                    }
                                }
                            }
                        }
                        StatusLine(
                            symbol: appState.shouldShowTokenIsland ? "circle.dotted.circle.fill" : "menubar.rectangle",
                            title: appState.tokenIslandStatus,
                            value: appState.tokenIslandStatusDetail,
                            tint: appState.shouldShowTokenIsland ? .tokenGreen : .gray
                        )
                    }
                }
            }

            HStack(alignment: .top, spacing: 12) {
                SettingsSectionCard(title: L("刷新"), subtitle: L("后台节奏 · 前台打开时总会即时刷")) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(L("间隔"))
                                .font(.callout.weight(.semibold))
                            Spacer()
                            HStack(spacing: 5) {
                                ForEach(refreshOptions) { option in
                                    SettingsPickerChip(
                                        title: option.title,
                                        selected: appState.settings.refreshIntervalSeconds == option.seconds
                                    ) {
                                        appState.setRefreshInterval(option.seconds)
                                    }
                                }
                            }
                        }
                        SettingsSourceRow(
                            title: L("省电策略"),
                            detail: L("电池或低电量时后台最短 30 分钟"),
                            badge: L("始终启用"),
                            badgeStyle: .ok
                        )
                    }
                }

                SettingsSectionCard(
                    title: L("更新与启动"),
                    subtitle: LFormat("当前版本 %@", UpdateService.currentVersion)
                ) {
                    VStack(spacing: 0) {
                        SettingsToggleRow(
                            title: L("自动检查更新"),
                            isOn: Binding(
                                get: { appState.settings.autoUpdateEnabled },
                                set: { appState.setAutoUpdateEnabled($0) }
                            )
                        )
                        SettingsToggleRow(
                            title: L("下载前询问"),
                            isOn: Binding(
                                get: { appState.settings.askBeforeDownloadingUpdates },
                                set: { appState.setAskBeforeDownloadingUpdates($0) }
                            )
                        )
                        SettingsToggleRow(
                            title: L("仅安装已签名公证版本"),
                            isOn: Binding(
                                get: { appState.settings.requireVerifiedUpdates },
                                set: { appState.setRequireVerifiedUpdates($0) }
                            )
                        )
                        SettingsToggleRow(
                            title: L("开机启动"),
                            isOn: Binding(
                                get: { appState.autostartEnabled },
                                set: { appState.setAutostart($0) }
                            )
                        )

                        Rectangle()
                            .fill(Color.tokenDivider)
                            .frame(height: 1)
                            .padding(.vertical, 8)

                        HStack(spacing: 9) {
                            Image(systemName: updateStatusSymbol)
                                .font(.system(size: 13, weight: .heavy))
                                .foregroundStyle(updateStatusTint)
                                .frame(width: 18)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(updateStatusTitle)
                                    .font(.caption.weight(.heavy))
                                    .foregroundStyle(Color.tokenInk)
                                Text(updateStatusDetail)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 6)

                            Button {
                                appState.showUpdateDetails()
                            } label: {
                                Text(updateButtonTitle)
                                    .font(.caption.weight(.heavy))
                                    .frame(minWidth: 64, minHeight: 28)
                            }
                            .buttonStyle(SettingsSecondaryButtonStyle())
                            .disabled(appState.isCheckingForUpdates)
                        }
                    }
                }
            }
        }
    }

    private var updateStatusSymbol: String {
        if appState.isCheckingForUpdates { return "arrow.triangle.2.circlepath" }
        if appState.availableUpdate != nil { return "arrow.down.circle.fill" }
        switch appState.updateCheckPhase {
        case .idle: return "arrow.down.circle"
        case .checking: return "arrow.triangle.2.circlepath"
        case .upToDate: return "checkmark.circle.fill"
        case .available: return "arrow.down.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var updateStatusTint: Color {
        if appState.availableUpdate != nil { return .tokenGreenDark }
        switch appState.updateCheckPhase {
        case .failed: return .red.opacity(0.82)
        case .upToDate: return .tokenSuccess
        default: return Color.tokenInk.opacity(0.60)
        }
    }

    private var updateStatusTitle: String {
        if appState.isCheckingForUpdates { return L("正在检查更新") }
        if let update = appState.availableUpdate {
            return LFormat("发现新版本 %@", update.version)
        }
        switch appState.updateCheckPhase {
        case .idle:
            return appState.lastUpdateCheckAt == nil ? L("尚未检查") : L("已是最新版本")
        case .checking: return L("正在检查更新")
        case .upToDate: return L("已是最新版本")
        case let .available(update, _): return LFormat("发现新版本 %@", update.version)
        case .failed: return L("更新检查失败")
        }
    }

    private var updateStatusDetail: String {
        switch appState.updateCheckPhase {
        case let .upToDate(checkedAt), let .available(_, checkedAt):
            return LFormat("上次检查 %@", updateTime(checkedAt))
        case let .failed(_, message):
            return message
        case .idle where appState.lastUpdateCheckAt != nil:
            return LFormat("上次检查 %@", updateTime(appState.lastUpdateCheckAt!))
        default:
            return LFormat("当前版本 %@", UpdateService.currentVersion)
        }
    }

    private var updateButtonTitle: String {
        if appState.isCheckingForUpdates { return L("检查中") }
        return appState.availableUpdate == nil ? L("检查更新") : L("查看更新")
    }

    private func updateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private var refreshOptions: [RefreshOption] {
        [
            RefreshOption(seconds: 60, title: L("1 分钟")),
            RefreshOption(seconds: 300, title: LFormat("%d 分钟", 5)),
            RefreshOption(seconds: 900, title: LFormat("%d 分钟", 15)),
            RefreshOption(seconds: 0, title: L("手动"))
        ]
    }
}
