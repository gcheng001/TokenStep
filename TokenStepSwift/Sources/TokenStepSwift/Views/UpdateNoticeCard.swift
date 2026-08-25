import SwiftUI

struct UpdateNoticeCard: View {
    @EnvironmentObject private var appState: AppState
    var update: AvailableUpdate

    var body: some View {
        HStack(alignment: .center, spacing: 13) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.tokenGreen)
                .frame(width: 38, height: 38)
                .background(Color.tokenMint.opacity(0.22), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(LFormat("发现新版本 %@", update.version))
                    .font(.callout.weight(.heavy))
                    .foregroundStyle(Color.tokenInk)
                Text(update.noteLines.first ?? L("内存占用优化与稳定性改进"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                appState.showUpdateDetails()
            } label: {
                Text(L("立即更新"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.tokenActionText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.tokenGreen, in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                appState.postponeUpdateNotice()
            } label: {
                Text(L("稍后"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Color.tokenInk.opacity(0.64))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Color.tokenTrack.opacity(0.42), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(13)
        .background(Color.tokenSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.tokenHairlineStrong))
    }
}
