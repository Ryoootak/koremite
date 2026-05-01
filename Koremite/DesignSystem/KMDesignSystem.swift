import SwiftUI

enum KMColor {
    static let background = Color(red: 0.91, green: 0.90, blue: 0.87)
    static let groupedBackground = Color(red: 0.96, green: 0.95, blue: 0.92)
    static let card = Color.white
    static let text = Color(red: 0.13, green: 0.16, blue: 0.13)
    static let secondaryText = Color(red: 0.38, green: 0.42, blue: 0.38)
    static let tertiaryText = Color(red: 0.58, green: 0.61, blue: 0.56)
    static let moss = Color(red: 0.23, green: 0.42, blue: 0.28)
    static let mossSoft = Color(red: 0.91, green: 0.95, blue: 0.89)
    static let stroke = Color(red: 0.86, green: 0.85, blue: 0.81)
    static let warning = Color(red: 0.72, green: 0.43, blue: 0.16)
}

enum KMSpacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 18
    static let xl: CGFloat = 24
}

struct KMCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(KMSpacing.lg)
            .background(KMColor.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(KMColor.stroke, lineWidth: 1)
            )
    }
}

struct KMChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? KMColor.moss : KMColor.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? KMColor.mossSoft : KMColor.card)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? KMColor.moss.opacity(0.35) : KMColor.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct KMPrimaryButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(isDisabled ? KMColor.tertiaryText : KMColor.moss)
                .clipShape(Capsule())
        }
        .disabled(isDisabled)
    }
}
