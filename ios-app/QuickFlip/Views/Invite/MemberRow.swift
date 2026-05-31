import SwiftUI

struct MemberRow: View {
    let member: BoardMember
    let isOwner: Bool
    let isYou: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var displayName: String { member.displayName ?? "?" }

    var body: some View {
        HStack(spacing: 12) {
            MemberAvatarBubble(name: displayName, size: 32)
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(displayName)
                        .font(.system(size: 16, weight: .semibold))
                    if isYou {
                        Text("· You")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer(minLength: 0)
            if isOwner {
                Text("OWNER")
                    .font(.system(size: 10, weight: .bold))
                    .kerning(0.6)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(colorScheme == .dark
                            ? Color.white.opacity(0.10)
                            : Color.black.opacity(0.06))
                    )
            }
        }
    }
}
