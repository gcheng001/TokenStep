import SwiftUI

struct PopoverModelUsageRow: Identifiable, Equatable {
    enum Kind: Equatable {
        case model(String)
        case other
    }

    var kind: Kind
    var tokens: Int
    var percent: Double
    var colorSlot: Int?

    var id: String {
        switch kind {
        case let .model(model): return "model:\(model)"
        case .other: return "aggregate:other"
        }
    }

    var originalModelName: String? {
        guard case let .model(model) = kind else { return nil }
        return model
    }
}
enum PopoverModelUsageState: Equatable {
    case hidden
    case waiting
    case rows([PopoverModelUsageRow], mismatch: Bool)
}

enum PopoverModelUsageRows {
    static let maximumIndividualRows = 3
    static let maximumVisibleRows = 4

    static func state(from usage: DailyUsage) -> PopoverModelUsageState {
        guard usage.totalTokens > 0 else { return .hidden }
        let sourceRows = TodayModelUsageRows.allPositiveRows(from: usage)
        guard !sourceRows.isEmpty else { return .waiting }

        var rows = sourceRows.prefix(maximumIndividualRows).map { source in
            PopoverModelUsageRow(
                kind: .model(source.model),
                tokens: source.tokens,
                percent: source.percent,
                colorSlot: TodayModelUsageRows.colorSlot(for: source.model)
            )
        }

        let remaining = sourceRows.dropFirst(maximumIndividualRows)
        if !remaining.isEmpty {
            let otherTokens = saturatedSum(remaining.map(\.tokens))
            rows.append(
                PopoverModelUsageRow(
                    kind: .other,
                    tokens: otherTokens,
                    percent: percent(tokens: otherTokens, total: usage.totalTokens),
                    colorSlot: nil
                )
            )
        }

        return .rows(
            rows,
            mismatch: TodayModelUsageRows.hasTokenTotalMismatch(usage)
        )
    }

    private static func percent(tokens: Int, total: Int) -> Double {
        guard total > 0 else { return 0 }
        return min(100, max(0, Double(tokens) * 100 / Double(total)))
    }

    private static func saturatedSum(_ values: [Int]) -> Int {
        values.reduce(into: 0) { result, value in
            let (sum, overflow) = result.addingReportingOverflow(value)
            result = overflow ? Int.max : sum
        }
    }
}

struct PopoverModelUsageSection: View {
    var usage: DailyUsage

    private var state: PopoverModelUsageState {
        PopoverModelUsageRows.state(from: usage)
    }

    @ViewBuilder
    var body: some View {
        switch state {
        case .hidden:
            EmptyView()
        case .waiting:
            content(rows: [], mismatch: false, waiting: true)
        case let .rows(rows, mismatch):
            content(rows: rows, mismatch: mismatch, waiting: false)
        }
    }

    private func content(
        rows: [PopoverModelUsageRow],
        mismatch: Bool,
        waiting: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            header(mismatch: mismatch)
                .frame(height: 20)

            if waiting {
                Text(L("模型明细同步中"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 32, alignment: .leading)
                    .accessibilityLabel(L("模型明细同步中"))
            } else {
                columnHeader
                    .frame(height: 18)
                ForEach(rows) { row in
                    modelRow(row)
                }
            }
        }
        .padding(.horizontal, TokenStepThemeRuntime.isCinematic ? 14 : 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func header(mismatch: Bool) -> some View {
        HStack(spacing: 7) {
            Text(L("今日模型"))
                .font((TokenStepThemeRuntime.isCinematic ? Font.callout : Font.caption).weight(.heavy))
                .foregroundStyle(Color.tokenInk)
            Spacer(minLength: 4)
            if mismatch {
                Image(systemName: "info.circle")
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundStyle(.secondary)
                    .help(L("模型明细合计与今日总量不一致；占比按今日总量计算。"))
                    .accessibilityLabel(L("模型明细合计与今日总量不一致；占比按今日总量计算。"))
            }
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 8) {
            Text(L("模型"))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Token")
                .frame(width: 68, alignment: .trailing)
            Text(L("占比"))
                .frame(width: 44, alignment: .trailing)
        }
        .font(.system(size: 9.5, weight: .semibold))
        .foregroundStyle(.secondary)
    }

    private func modelRow(_ row: PopoverModelUsageRow) -> some View {
        let color = rowColor(row)
        let name = displayName(row)
        return VStack(spacing: 3) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                    Text(name)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(row.originalModelName ?? name)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(TokenStepFormat.tokens(row.tokens, compact: true))
                    .frame(width: 68, alignment: .trailing)
                    .monospacedDigit()
                Text(TokenStepFormat.percent(row.percent))
                    .frame(width: 44, alignment: .trailing)
                    .monospacedDigit()
            }
            .font(.system(size: TokenStepThemeRuntime.isCinematic ? 10.5 : 10, weight: .semibold))
            .foregroundStyle(Color.tokenInk.opacity(0.82))

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.tokenTrack.opacity(0.78))
                    Capsule()
                        .fill(color)
                        .frame(width: max(row.tokens > 0 ? 3 : 0, proxy.size.width * row.percent / 100))
                }
            }
            .frame(height: 3)
            .padding(.leading, 12)
        }
        .frame(height: 25)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(name), \(TokenStepFormat.tokens(row.tokens, compact: true)), \(TokenStepFormat.percent(row.percent))"
        )
    }

    private func displayName(_ row: PopoverModelUsageRow) -> String {
        switch row.kind {
        case .other:
            return L("其他")
        case let .model(model):
            return model.lowercased() == "unknown" ? L("未知模型") : model
        }
    }

    private func rowColor(_ row: PopoverModelUsageRow) -> Color {
        guard let slot = row.colorSlot else {
            return Color.secondary.opacity(0.72)
        }
        if TokenStepThemeRuntime.isCinematic {
            switch slot {
            case 0: return .tokenGreen
            case 1: return TokenStepThemeRuntime.palette.activity3.color
            case 2: return TokenStepThemeRuntime.palette.activity2.color
            default: return .tokenGreenDark
            }
        }
        switch slot {
        case 0: return .tokenGreen
        case 1: return Color(red: 0.19, green: 0.52, blue: 0.91)
        case 2: return Color.tokenInk.opacity(0.55)
        default: return .tokenGreenDark
        }
    }
}
