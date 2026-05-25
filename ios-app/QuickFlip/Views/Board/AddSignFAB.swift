import SwiftUI

struct AddSignFAB: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed = false

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: {
            HapticManager.medium()
            action()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.black)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color(hex: "FFD600"))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                .blendMode(.overlay)
                        )
                )
                .shadow(color: isDark
                        ? Color(hex: "FFD600").opacity(0.45)
                        : Color(hex: "B48200").opacity(0.35),
                        radius: isDark ? 36 : 28, y: isDark ? 14 : 12)
                .shadow(color: .black.opacity(isDark ? 0.35 : 0.12),
                        radius: 6, y: 2)
                .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.05)) { isPressed = pressing }
            },
            perform: {}
        )
        .accessibilityLabel("Add sign")
    }
}
