import SwiftUI

struct SignCardView: View {
    let sign: Sign
    let userNickname: String
    let signsVM: SignsViewModel
    let onDelete: () -> Void
    let index: Int

    @State private var isFlipping = false
    @State private var showDeleteButton = false

    var palette: SignPalette {
        SIGN_PALETTES[sign.colorIndex % SIGN_PALETTES.count]
    }

    var cardGradient: LinearGradient {
        let lightColor = sign.active ? palette.onLight : palette.offLight
        let darkColor = sign.active ? palette.onDark : palette.offDark
        return LinearGradient(
            gradient: Gradient(colors: [lightColor, darkColor]),
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                if showDeleteButton {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    Color.clear.frame(width: 26, height: 26)
                }

                Spacer()

                Text(sign.emoji)
                    .font(.system(size: 32))

                Spacer()

                Color.clear.frame(width: 26, height: 26)
            }

            VStack(alignment: .center, spacing: 6) {
                Text(sign.label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(sign.currentStateLabel)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(20)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                if let lastChangedBy = sign.lastChangedBy {
                    Text(lastChangedBy)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                if let lastChangedAt = sign.lastChangedAt {
                    Text(timeAgo(from: lastChangedAt))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(cardGradient)
        .cornerRadius(12)
        .scaleEffect(isFlipping ? 0.94 : 1.0)
        .rotation3DEffect(.degrees(isFlipping ? 8 : 0), axis: (x: 1, y: 0, z: 0))
        .onTapGesture {
            if showDeleteButton {
                showDeleteButton = false
            } else {
                HapticManager.medium()
                isFlipping = true

                Task {
                    await signsVM.toggleSign(sign, userNickname: userNickname)
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    withAnimation(.spring(response: 0.25)) {
                        isFlipping = false
                    }
                }
            }
        }
        .onLongPressGesture {
            HapticManager.heavy()
            showDeleteButton.toggle()
        }
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
        onDelete: {},
        index: 0
    )
}
