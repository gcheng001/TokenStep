import AppKit
import SwiftUI

struct PopoverPanelView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.isScreenshotRendering) private var isScreenshotRendering
    @State private var odysseyMotionSurfaceVisible = false
    @State private var interstellarMotionMode = InterstellarMotionLabConfiguration.initialMode
    @State private var interstellarManualPulseTrigger = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if TokenStepThemeRuntime.isCinematic {
                cinematicContent
            } else {
                classicColumns
            }
            notices
            PopoverFooterView()
                .padding(.horizontal, TokenStepThemeRuntime.isCinematic ? 22 : 16)
                .padding(.top, TokenStepThemeRuntime.isCinematic ? 14 : 12)
                .padding(.bottom, TokenStepThemeRuntime.isCinematic ? 20 : 14)
        }
        .frame(width: 900)
        .background {
            if TokenStepThemeRuntime.isInterstellar {
                InterstellarBackdrop(
                    role: .popover,
                    isScreenshotRendering: isScreenshotRendering,
                    motionMode: interstellarMotionMode,
                    tokenActivity: appState.today.totalTokens,
                    manualPulseTrigger: interstellarManualPulseTrigger
                )
            } else if TokenStepThemeRuntime.isVoyage {
                OdysseyPopoverBackdrop(
                    isMotionSurfaceActive: odysseyMotionSurfaceVisible,
                    isScreenshotRendering: isScreenshotRendering
                )
            } else {
                TokenStepBackdrop(role: .popover)
            }
        }
        .background {
            if TokenStepThemeRuntime.isVoyage && !isScreenshotRendering {
                OdysseySurfaceVisibilityReader(isVisible: $odysseyMotionSurfaceVisible)
                    .frame(width: 1, height: 1)
            }
        }
        .overlay {
            if TokenStepThemeRuntime.isVoyage {
                OdysseyPopoverWindowFrame(inset: 7)
            } else if TokenStepThemeRuntime.isInterstellar {
                InterstellarWindowFrame(inset: 7)
            }
        }
        .environment(\.colorScheme, appState.settings.theme.colorScheme)
        .id(appState.appearanceID)
        .onAppear {
            if !isScreenshotRendering {
                appState.refreshForForeground()
            }
        }
        .onDisappear {
            odysseyMotionSurfaceVisible = false
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            TokenStepBrandLockup(
                markSize: TokenStepThemeRuntime.isCinematic ? 34 : 28,
                titleSize: TokenStepThemeRuntime.isCinematic ? 20 : 17
            )
            Spacer()
            if TokenStepThemeRuntime.isInterstellar,
               InterstellarMotionLabConfiguration.isEnabled {
                InterstellarMotionLabPicker(
                    mode: $interstellarMotionMode,
                    triggerPulse: {
                        interstellarManualPulseTrigger &+= 1
                    }
                )
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isRefreshing ? Color.secondary.opacity(0.68) : Color.tokenSuccess)
                    .frame(width: 7, height: 7)
                Text(appState.isRefreshing ? L("同步中") : L("已同步"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.tokenInk.opacity(0.72))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.tokenSurface, in: Capsule())
            .overlay(Capsule().stroke(Color.tokenDivider))

            if !isScreenshotRendering {
                PopoverCaptureMenuButton(
                    shareTodayAction: { copyShareCard(.today) },
                    shareYesterdayAction: { copyShareCard(.yesterday) },
                    shareYesterdayRhythmAction: copyYesterdayRhythmCard,
                    downloadTodayAction: { downloadShareCard(.today) },
                    downloadYesterdayRhythmAction: downloadYesterdayRhythmCard,
                    copyPopoverAction: copyPopoverScreenshot,
                    savePopoverAction: savePopoverScreenshot
                )
            }
        }
        .padding(.horizontal, TokenStepThemeRuntime.isCinematic ? 26 : 16)
        .frame(height: TokenStepThemeRuntime.isCinematic ? 72 : 48)
        .background {
            if TokenStepThemeRuntime.isCinematic {
                LinearGradient(
                    colors: [Color.black.opacity(0.30), Color.tokenCanvas.opacity(0.12), Color.black.opacity(0.16)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        }
        .overlay(alignment: .bottom) {
            if TokenStepThemeRuntime.isCinematic {
                LinearGradient(
                    colors: [Color.tokenGreen.opacity(0.58), Color.tokenDivider.opacity(0.34), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                .padding(.horizontal, 22)
            }
        }
    }

    private var cinematicContent: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                PopoverTodayRingCard()
                    .frame(width: 250, height: odysseyTopCardHeight)
                    .background(cinematicSectionBackground(opacity: TokenStepThemeRuntime.isInterstellar ? 0.66 : 0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                centralUsageCard
                    .frame(minWidth: 330, maxWidth: .infinity, minHeight: odysseyTopCardHeight, maxHeight: odysseyTopCardHeight)
                    .background(cinematicSectionBackground(opacity: TokenStepThemeRuntime.isInterstellar ? 0.70 : 0.46))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                if appState.showsQuotaColumn {
                    PopoverQuotaCard()
                        .frame(width: 260, height: odysseyTopCardHeight)
                        .background(cinematicSectionBackground(opacity: TokenStepThemeRuntime.isInterstellar ? 0.74 : 0.54))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            if appState.shouldShowAgentWorkRank, appState.agentWorkRankIdentity != nil {
                PopoverTokenRankCard(layout: .ribbon)
                    .frame(height: 76)
                    .background(cinematicSectionBackground(opacity: TokenStepThemeRuntime.isInterstellar ? 0.76 : 0.58, cornerRadius: 16))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var classicColumns: some View {
        HStack(alignment: .top, spacing: 0) {
            PopoverTodayRingCard()
                .frame(width: 188)
            columnDivider
            centralUsageCard
                .frame(minWidth: 240, maxWidth: .infinity)
            if appState.showsQuotaColumn {
                columnDivider
                PopoverQuotaCard()
                    .frame(width: quotaColumnWidth)
            }
            if appState.shouldShowAgentWorkRank, appState.agentWorkRankIdentity != nil {
                columnDivider
                PopoverTokenRankCard()
                    .frame(width: 196)
            }
        }
        .frame(minHeight: columnsMinHeight)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.tokenDivider)
                .frame(height: 1)
        }
    }

    private var quotaColumnWidth: CGFloat {
        appState.visibleQuotas.count >= 4 ? 248 : 208
    }

    private var odysseyTopCardHeight: CGFloat { 288 }

    @ViewBuilder
    private func cinematicSectionBackground(opacity: Double, cornerRadius: CGFloat = 18) -> some View {
        if TokenStepThemeRuntime.isInterstellar {
            InterstellarPanelBackground(opacity: opacity, cornerRadius: cornerRadius)
        } else {
            OdysseyPopoverSectionBackground(opacity: opacity, cornerRadius: cornerRadius)
        }
    }

    private var showsModelUsageSection: Bool {
        switch PopoverModelUsageRows.state(from: appState.today) {
        case .hidden: return false
        case .waiting, .rows: return true
        }
    }

    private var centralUsageCard: some View {
        let voyage = TokenStepThemeRuntime.isCinematic
        return VStack(spacing: 0) {
            PopoverAgentWorkTable()
                .frame(height: voyage ? (showsModelUsageSection ? 128 : odysseyTopCardHeight) : nil)

            if showsModelUsageSection {
                Rectangle()
                    .fill(Color.tokenDivider)
                    .frame(height: 1)
                    .padding(.horizontal, voyage ? 14 : 12)

                PopoverModelUsageSection(usage: appState.today)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: voyage ? .infinity : nil, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture {
            MainWindowPresenter.shared.show(appState: appState, section: .today)
        }
    }

    private var columnsMinHeight: CGFloat {
        appState.visibleQuotas.count >= 5 ? 300 : 248
    }

    private var columnDivider: some View {
        Rectangle().fill(Color.tokenDivider)
        .frame(width: 1)
    }

    @ViewBuilder
    private var notices: some View {
        VStack(spacing: 8) {
            if let error = appState.lastError {
                ErrorBanner(message: error) {
                    appState.clearError()
                }
            }
            if appState.showsUsageRecalibrationNotice {
                UsageRecalibrationNotice {
                    appState.dismissUsageRecalibrationNotice()
                }
            }
            if let update = appState.availableUpdate {
                UpdateNoticeCard(update: update)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, appState.lastError == nil && !appState.showsUsageRecalibrationNotice && appState.availableUpdate == nil ? 0 : 10)
    }

    private func copyShareCard(_ mode: ShareCardMode) {
        guard let day = shareDay(for: mode) else {
            appState.lastError = mode == .yesterday ? L("还没有昨日数据") : L("等待下一次同步")
            return
        }

        do {
            try ScreenshotExporter.copy(
                ShareDailyCardView(
                    mode: mode,
                    day: day,
                    previousDay: previousDay(before: day)
                )
                .environmentObject(appState)
                .environment(\.isScreenshotRendering, true)
            )
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func downloadShareCard(_ mode: ShareCardMode) {
        guard let day = shareDay(for: mode) else {
            appState.lastError = mode == .yesterday ? L("还没有昨日数据") : L("等待下一次同步")
            return
        }

        do {
            try ScreenshotExporter.saveJPGToDownloads(
                ShareDailyCardView(
                    mode: mode,
                    day: day,
                    previousDay: previousDay(before: day)
                )
                .environmentObject(appState)
                .environment(\.isScreenshotRendering, true)
            )
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func copyYesterdayRhythmCard() {
        guard let payload = yesterdayRhythmPayload() else { return }

        do {
            try ScreenshotExporter.copy(
                ShareRhythmCardView(
                    day: payload.day,
                    rhythm: payload.rhythm,
                    previousDay: payload.previousDay
                )
                .environmentObject(appState)
                .environment(\.isScreenshotRendering, true)
            )
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func downloadYesterdayRhythmCard() {
        guard let payload = yesterdayRhythmPayload() else { return }

        do {
            try ScreenshotExporter.saveJPGToDownloads(
                ShareRhythmCardView(
                    day: payload.day,
                    rhythm: payload.rhythm,
                    previousDay: payload.previousDay
                )
                .environmentObject(appState)
                .environment(\.isScreenshotRendering, true)
            )
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private var popoverScreenshot: some View {
        PopoverPanelView()
            .environmentObject(appState)
            .environment(\.isScreenshotRendering, true)
    }

    private func copyPopoverScreenshot() {
        do {
            try ScreenshotExporter.copy(popoverScreenshot)
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func savePopoverScreenshot() {
        do {
            try ScreenshotExporter.save(
                popoverScreenshot,
                suggestedFileName: ScreenshotExporter.suggestedFileName(prefix: "popover")
            )
        } catch {
            appState.lastError = error.localizedDescription
        }
    }

    private func shareDay(for mode: ShareCardMode) -> DailyUsage? {
        switch mode {
        case .today:
            return appState.today.totalTokens > 0 ? appState.today : nil
        case .yesterday:
            let calendar = Calendar(identifier: .gregorian)
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) else {
                return nil
            }
            let key = DateFormatter.tokenStepDay.string(from: yesterday)
            return appState.snapshot.daily.first(where: { $0.date == key && $0.totalTokens > 0 })
        }
    }

    private func previousDay(before day: DailyUsage) -> DailyUsage? {
        let rows = appState.snapshot.daily.sorted { $0.date < $1.date }
        guard let index = rows.firstIndex(where: { $0.date == day.date }), index > rows.startIndex else {
            return nil
        }
        return rows[rows.index(before: index)]
    }

    private func yesterdayRhythmPayload() -> (day: DailyUsage, rhythm: DailyRhythm, previousDay: DailyUsage?)? {
        guard let day = shareDay(for: .yesterday) else {
            appState.lastError = L("还没有昨日数据")
            return nil
        }
        guard let rhythm = appState.snapshot.rhythm(for: day.date) else {
            appState.lastError = L("昨日节奏还在等待同步")
            return nil
        }
        return (day, rhythm, previousDay(before: day))
    }
}

private struct PopoverCaptureMenuButton: View {
    var shareTodayAction: () -> Void
    var shareYesterdayAction: () -> Void
    var shareYesterdayRhythmAction: () -> Void
    var downloadTodayAction: () -> Void
    var downloadYesterdayRhythmAction: () -> Void
    var copyPopoverAction: () -> Void
    var savePopoverAction: () -> Void

    var body: some View {
        Menu {
            Button {
                shareYesterdayRhythmAction()
            } label: {
                Label(L("分享昨日节奏"), systemImage: "waveform.path.ecg")
            }

            Button {
                shareYesterdayAction()
            } label: {
                Label(L("分享昨日成绩"), systemImage: "calendar.badge.clock")
            }

            Button {
                shareTodayAction()
            } label: {
                Label(L("分享今日卡片"), systemImage: "sun.max.fill")
            }

            Divider()

            Button {
                downloadYesterdayRhythmAction()
            } label: {
                Label(L("下载昨日节奏"), systemImage: "arrow.down.heart.fill")
            }

            Button {
                downloadTodayAction()
            } label: {
                Label(L("下载今日卡片"), systemImage: "arrow.down.circle.fill")
            }

            Divider()

            Button {
                copyPopoverAction()
            } label: {
                Label(L("复制浮层截图"), systemImage: "doc.on.clipboard")
            }

            Button {
                savePopoverAction()
            } label: {
                Label(L("保存浮层 PNG"), systemImage: "square.and.arrow.down")
            }
        } label: {
            Image(systemName: "camera.fill")
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(Color.tokenInk.opacity(0.76))
                .frame(width: 30, height: 30)
                .background(Color.tokenSurface, in: Circle())
                .overlay(Circle().stroke(Color.tokenHairline))
                .contentShape(Circle())
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .help(L("截图与分享"))
        .accessibilityLabel(L("截图与分享"))
    }
}
