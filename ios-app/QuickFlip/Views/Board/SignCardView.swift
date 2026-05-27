import SwiftUI

struct SignCardView: View {
    let sign: Sign
    let userNickname: String
    let signsVM: SignsViewModel
    let onEdit: () -> Void
    let onDelete: () -> Void
    let index: Int

    @Environment(\.colorScheme) private var colorScheme
    @State private var isFlipping = false

    private let cardRadius = SignCardDesign.cardRadius
    private let cardPadding = SignCardDesign.cardPadding
    private let cardMinHeight = SignCardDesign.cardMinHeight
    private let yellow = Color(hex: "FFD600")
    private let yellowDeep = Color(hex: "9A7B00")

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(sign.emoji)
                    .font(.system(size: SignCardDesign.emojiSize))
                    .shadow(color: .black.opacity(isDark ? 0.45 : 0.15), radius: 6, y: 2)

                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 3) {
                Text(sign.label.uppercased())
                    .font(SignCardDesign.eyebrowFont)
                    .kerning(1.0)
                    .foregroundColor(eyebrowColor)

                Text(sign.currentStateLabel)
                    .font(SignCardDesign.stateFont)
                    .kerning(-0.5)
                    .foregroundColor(stateWordColor)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 6) {
                AvatarBubble(name: sign.lastChangedBy ?? "?")
                Text(sign.lastChangedBy ?? "—")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(primaryTextStrong)
                Text("·").foregroundColor(primaryTextMuted)
                if let date = sign.lastChangedAt {
                    Text(timeAgo(from: date))
                        .font(.system(size: 11))
                        .foregroundColor(primaryTextMuted)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(cardPadding)
        .frame(maxWidth: .infinity, minHeight: cardMinHeight, alignment: .topLeading)
        .background(cardSurface)
        .overlay(activeTint)
        .overlay(borderStroke)
        .shadow(color: .black.opacity(isDark ? 0.30 : 0.12), radius: isDark ? 22 : 24, y: isDark ? 8 : 10)
        .shadow(color: isDark ? .clear : .black.opacity(0.06), radius: 6, y: 2)
        .shadow(color: sign.active && isDark ? yellow.opacity(0.18) : .clear, radius: 24)
        .scaleEffect(isFlipping ? 0.94 : 1.0)
        .opacity(isFlipping ? 0.7 : 1.0)
        .onTapGesture { handleTap() }
        .contextMenu {
            Button {
                HapticManager.light()
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                HapticManager.heavy()
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var eyebrowColor: Color {
        if sign.active { return isDark ? yellow : yellowDeep }
        return isDark ? .white.opacity(0.50) : Color(hex: "0F1115").opacity(0.55)
    }

    private var stateWordColor: Color {
        if isDark { return sign.active ? yellow : .white }
        return Color(hex: "0F1115")
    }

    private var primaryTextStrong: Color {
        isDark ? .white.opacity(0.85) : Color(hex: "0F1115").opacity(0.9)
    }

    private var primaryTextMuted: Color {
        isDark ? .white.opacity(0.55) : Color(hex: "0F1115").opacity(0.6)
    }

    @ViewBuilder
    private var cardSurface: some View {
        if #available(iOS 26, *) {
            RoundedRectangle(cornerRadius: cardRadius)
                .fill(isDark ? Color.white.opacity(0.08) : Color.white.opacity(0.88))
                .glassEffect(in: .rect(cornerRadius: cardRadius))
        } else if #available(iOS 17, *) {
            RoundedRectangle(cornerRadius: cardRadius)
                .fill(isDark ? Color.clear : Color.white.opacity(0.4))
                .background(.regularMaterial, in: .rect(cornerRadius: cardRadius))
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(isDark ? Color(uiColor: .secondarySystemBackground) : Color.white)
        }
    }

    @ViewBuilder
    private var activeTint: some View {
        if sign.active {
            RoundedRectangle(cornerRadius: cardRadius)
                .fill(yellow.opacity(isDark ? 0.12 : 0.42))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var borderStroke: some View {
        RoundedRectangle(cornerRadius: cardRadius)
            .strokeBorder(borderColor, lineWidth: 0.5)
    }

    private var borderColor: Color {
        if sign.active {
            return isDark ? yellow.opacity(0.45) : yellowDeep.opacity(0.55)
        }
        return isDark ? .white.opacity(0.18) : .black.opacity(0.06)
    }

    private func handleTap() {
        HapticManager.medium()
        withAnimation(.easeInOut(duration: 0.15)) { isFlipping = true }
        Task {
            await signsVM.toggleSign(sign, userNickname: userNickname)
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.spring(response: 0.25)) { isFlipping = false }
        }
    }
}

private struct AvatarBubble: View {
    let name: String

    private var initial: String { String(name.prefix(1)).uppercased() }
    private var color: Color {
        let palette: [Color] = [
            Color(hex: "FF8A3D"),
            Color(hex: "22D3EE"),
            Color(hex: "9B5BFF"),
            Color(hex: "1ED760"),
            Color(hex: "FF4DCB"),
        ]
        let stableHash = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[stableHash % palette.count]
    }

    var body: some View {
        Text(initial)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(color))
    }
}

#Preview {
    SignCardView(
        sign: Sign(
            id: UUID(),
            boardId: UUID(),
            label: "Dishwasher",
            emoji: "🍽️",
            stateOffLabel: "Dirty",
            stateOnLabel: "Clean",
            active: false,
            lastChangedAt: Date(),
            lastChangedBy: "Alice",
            position: 0,
            colorIndex: 0,
            createdAt: Date()
        ),
        userNickname: "Alice",
        signsVM: SignsViewModel(),
        onEdit: {},
        onDelete: {},
        index: 0
    )
}
