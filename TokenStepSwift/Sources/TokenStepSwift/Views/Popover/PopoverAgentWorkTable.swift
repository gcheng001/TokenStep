import SwiftUI

struct PopoverAgentWorkTable: View {
    @EnvironmentObject private var appState: AppState

    private var work: DailyAgentWork {
        appState.todayAgentWork
    }

    var body: some View {
        let voyage = TokenStepThemeRuntime.isVoyage
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L("Agent 用量"))
                    .font((voyage ? Font.callout : Font.caption).weight(.heavy))
                    .foregroundStyle(Color.tokenInk)
                Spacer()
                Text(LFormat("%d 个来源", rows.count))
                    .font((voyage ? Font.caption : Font.caption2).weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 20)

            if rows.isEmpty {
                Text(L("今日还没有 Agent 记录"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
            } else {
                header
                    .frame(height: 18)
                ForEach(visibleRows) { row in
                    rowView(row)
                }
            }
        }
        .padding(.horizontal, voyage ? 14 : 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .onTapGesture {
            MainWindowPresenter.shared.show(appState: appState, section: .today)
        }
    }

    private var header: some View {
        let voyage = TokenStepThemeRuntime.isVoyage
        return HStack(spacing: 10) {
            Text(L("来源")).frame(maxWidth: .infinity, alignment: .leading)
            Text(L("Token")).frame(width: voyage ? 88 : 72, alignment: .trailing)
        }
        .font(.system(size: voyage ? 11.5 : 10.5, weight: .semibold))
        .foregroundStyle(.secondary)
    }

    private func rowView(_ row: AgentWorkSource) -> some View {
        let voyage = TokenStepThemeRuntime.isVoyage
        return HStack(alignment: .center, spacing: 10) {
            HStack(alignment: .center, spacing: 6) {
                Circle()
                    .fill(tokenToolColor(row.source))
                    .frame(width: 6, height: 6)
                Text(row.source)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.leading)
                    .help(row.source)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(TokenStepFormat.tokens(row.tokens, compact: true))
                .frame(width: voyage ? 88 : 72, alignment: .trailing)
                .monospacedDigit()
        }
        .font(.system(size: voyage ? 11.5 : 10.5, weight: .semibold))
        .foregroundStyle(Color.tokenInk.opacity(0.82))
        .frame(height: 25)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.tokenDivider).frame(height: 1)
        }
    }

    private var rows: [AgentWorkSource] {
        work.sources
            .filter { $0.tokens > 0 }
            .sorted {
                if $0.tokens != $1.tokens { return $0.tokens > $1.tokens }
                return $0.source.localizedStandardCompare($1.source) == .orderedAscending
            }
    }

    private var visibleRows: [AgentWorkSource] {
        Array(rows.prefix(3))
    }
}
