import SwiftUI

struct PopoverTodayRingCard: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        let lap = appState.todayLap
        let voyage = TokenStepThemeRuntime.isCinematic
        let ringSize: CGFloat = voyage ? 164 : 118
        let lineWidth: CGFloat = voyage ? 14 : 12

        return VStack(spacing: voyage ? 13 : 10) {
            HStack {
                Text(L("今日消耗"))
                    .font((voyage ? Font.callout : Font.caption).weight(.heavy))
                    .foregroundStyle(Color.tokenInk)
                Spacer()
                Text(appState.today.date.suffix(5))
                    .font((voyage ? Font.caption : Font.caption2).weight(.bold))
                    .foregroundStyle(.secondary)
            }

            ZStack {
                if TokenStepThemeRuntime.isVoyage {
                    Circle()
                        .fill(Color.tokenCanvas.opacity(0.42))
                        .padding(12)
                        .blur(radius: 0.2)
                    VoyageBowProgressView(progress: lap.currentLapProgress, lineWidth: lineWidth, color: lap.ringColor)
                } else if TokenStepThemeRuntime.isInterstellar {
                    Circle()
                        .fill(Color.black.opacity(0.52))
                        .padding(12)
                    ProgressRingView(progress: lap.currentLapProgress, lineWidth: lineWidth, color: lap.ringColor)
                        .overlay {
                            InterstellarEventHorizonEmblem()
                                .padding(30)
                                .opacity(0.50)
                        }
                } else {
                    ProgressRingView(progress: lap.currentLapProgress, lineWidth: lineWidth, color: lap.ringColor)
                }
                VStack(spacing: 2) {
                    Text(TokenStepFormat.tokens(appState.today.totalTokens, compact: true))
                        .font(.system(size: voyage ? 24 : 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.tokenInk)
                        .minimumScaleFactor(0.62)
                        .lineLimit(1)
                    Text(LFormat("/ %@", TokenStepFormat.tokens(appState.settings.dailyGoalTokens, compact: true)))
                        .font((voyage ? Font.caption : Font.caption2).weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .frame(width: voyage ? 118 : 88)
            }
            .frame(width: ringSize, height: ringSize)

            VStack(spacing: voyage ? 5 : 3) {
                Text(lap.lapStatusText)
                    .font((voyage ? Font.callout : Font.caption).weight(.heavy))
                    .foregroundStyle(Color.tokenInk)
                Text(TokenStepFormat.money(appState.today.cost))
                    .font((voyage ? Font.caption : Font.caption2).weight(.bold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(voyage ? 18 : 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
