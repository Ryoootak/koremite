import SwiftUI

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.18).ignoresSafeArea()
            VStack(spacing: KMSpacing.md) {
                ProgressView()
                    .tint(KMColor.moss)
                    .scaleEffect(1.2)
                Text("文字起こしを整理しています")
                    .font(.headline)
                Text("短くまとめと詳しくまとめを作成中")
                    .font(.subheadline)
                    .foregroundStyle(KMColor.secondaryText)
            }
            .padding(KMSpacing.xl)
            .background(KMColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 12)
        }
    }
}
