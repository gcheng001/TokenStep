import AppKit
import SwiftUI

struct PopoverFooterView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if TokenStepThemeRuntime.isCinematic {
                odysseyFooter
            } else {
                classicFooter
            }
        }
    }

    private var classicFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(L("本地统计"), systemImage: "checkmark.shield.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(appState.settings.refreshIntervalSeconds == 0 ? L("手动刷新") : LFormat("刷新 %@", TokenStepFormat.intervalLabel(appState.settings.refreshIntervalSeconds)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    MainWindowPresenter.shared.show(appState: appState)
                } label: {
                    Label(L("打开仪表盘"), systemImage: "arrow.up.right")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.tokenActionText)
                        .frame(width: 148, height: 40)
                        .background(Color.tokenGreen, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(L("打开仪表盘"))

                Spacer(minLength: 0)

                PopoverActionButton(title: L("刷新"), symbol: "arrow.clockwise") {
                    appState.refresh()
                }
                .disabled(appState.isRefreshing)

                PopoverUpdateActionButton()

                PopoverActionButton(title: L("设置"), symbol: "gearshape") {
                    SettingsWindowPresenter.shared.show(appState: appState)
                }

                PopoverActionButton(title: L("退出"), symbol: "power") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

    private var odysseyFooter: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Label(L("本地统计"), systemImage: "checkmark.shield.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                Button {
                    MainWindowPresenter.shared.show(appState: appState)
                } label: {
                    Label(L("打开仪表盘"), systemImage: "arrow.up.right")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.tokenActionText)
                        .frame(width: 190, height: 44)
                        .background(
                            LinearGradient(
                                colors: [Color.tokenGreenDark, Color.tokenGreen],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
                        }
                        .shadow(color: Color.black.opacity(0.28), radius: 12, y: 6)
                }
                .buttonStyle(.plain)
                .help(L("打开仪表盘"))
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 10) {
                Text(appState.settings.refreshIntervalSeconds == 0 ? L("手动刷新") : LFormat("刷新 %@", TokenStepFormat.intervalLabel(appState.settings.refreshIntervalSeconds)))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    PopoverActionButton(title: L("刷新"), symbol: "arrow.clockwise") {
                        appState.refresh()
                    }
                    .disabled(appState.isRefreshing)

                    PopoverUpdateActionButton()

                    PopoverActionButton(title: L("设置"), symbol: "gearshape") {
                        SettingsWindowPresenter.shared.show(appState: appState)
                    }

                    PopoverActionButton(title: L("退出"), symbol: "power") {
                        NSApplication.shared.terminate(nil)
                    }
                }
            }
        }
    }
}

private struct PopoverUpdateActionButton: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Button {
            appState.showUpdateDetails()
        } label: {
            ZStack {
                if state.isChecking {
                    ProgressView()
                        .controlSize(.small)
                        .tint(state.tint)
                } else {
                    Image(systemName: state.symbol)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(state.tint)
                }

                if state.isAvailable {
                    Circle()
                        .fill(Color.tokenGreen)
                        .frame(width: 5.5, height: 5.5)
                        .offset(x: 12, y: -12)
                }
            }
            .frame(width: 40, height: 40)
            .background(Color.tokenSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(state.isAvailable ? Color.tokenGreen.opacity(0.56) : Color.tokenHairline)
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(state.isChecking)
        .help(state.help)
        .accessibilityLabel(state.accessibilityLabel)
    }

    private var state: UpdateActionVisualState {
        appState.updateActionVisualState
    }
}

private struct PopoverActionButton: View {
    var title: String
    var symbol: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(Color.tokenInk.opacity(0.78))
                .frame(width: 40, height: 40)
                .background(Color.tokenSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.tokenHairline))
                .help(title)
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
    }
}
