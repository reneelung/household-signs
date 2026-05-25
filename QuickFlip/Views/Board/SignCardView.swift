import SwiftUI

struct SignCardView: View {
    @State var sign: Sign
    let userNickname: String
    let signsVM: SignsViewModel
    let onDelete: () -> Void

    @State private var isFlipping = false
    @State private var showDeleteButton = false

    var stateColor: Color {
        sign.active ? Color.signActive : Color.signInactive
    }

    var stateBgColor: Color {
        sign.active ? Color.signActiveBg : Color.signInactiveBg
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(sign.emoji)
                    .font(.system(size: 32))

                Spacer()

                if showDeleteButton {
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.appSecondary)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(sign.label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appText)
                    .lineLimit(1)

                Text(sign.currentStateLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(stateColor)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(stateBgColor)
                    .cornerRadius(4)
                    .frame(alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                if let lastChangedBy = sign.lastChangedBy {
                    Text(lastChangedBy)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.appSecondary)
                }

                if let lastChangedAt = sign.lastChangedAt {
                    Text(timeAgo(from: lastChangedAt))
                        .font(.system(size: 10))
                        .foregroundColor(.appSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(minHeight: 120)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
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
            createdAt: Date()
        ),
        userNickname: "Alice",
        signsVM: SignsViewModel(),
        onDelete: {}
    )
}
