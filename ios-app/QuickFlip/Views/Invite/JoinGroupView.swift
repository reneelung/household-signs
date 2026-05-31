import SwiftUI

struct JoinGroupView: View {
    let inviteCode: String
    @Bindable var authVM: AuthViewModel
    @Bindable var boardVM: BoardViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var preview: BoardPreview?
    @State private var loadError: String?
    @State private var isJoining = false

    private let yellow = Color(hex: "FFD600")
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        ZStack {
            AmbientBackdrop(palette: .forest)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "square.stack.3d.up.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(yellow)
                    Text("QUICKFLIP")
                        .font(.system(size: 13, weight: .bold))
                        .kerning(1)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 64)

                Spacer()

                if let preview {
                    invitationContent(preview: preview)
                } else if let loadError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                        Text(loadError)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 32)
                    }
                } else {
                    ProgressView().tint(.white)
                }

                Spacer()

                VStack(spacing: 10) {
                    Button {
                        joinTapped()
                    } label: {
                        Text(isJoining ? "Joining…" : "Join Group")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(yellow))
                            .foregroundStyle(.black)
                            .shadow(color: yellow.opacity(0.45), radius: 30, y: 12)
                    }
                    .disabled(preview == nil || isJoining)
                    .buttonStyle(.plain)

                    Button("Not now") {
                        PendingJoin.shared.clear()
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 10)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 32)
            }
        }
        .task {
            do {
                preview = try await boardVM.fetchBoardPreview(inviteCode: inviteCode)
            } catch {
                loadError = error.localizedDescription
            }
        }
    }

    @ViewBuilder
    private func invitationContent(preview: BoardPreview) -> some View {
        VStack(spacing: 12) {
            MemberAvatarBubble(name: preview.inviterName ?? "?", size: 56)

            (Text(preview.inviterName ?? "Someone").bold()
                + Text(" invited you to join"))
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Text(preview.boardName)
                .font(.system(size: 38, weight: .heavy))
                .kerning(-1.4)
                .padding(.top, 2)

            if !preview.signEmojis.isEmpty {
                HStack(spacing: 6) {
                    ForEach(Array(preview.signEmojis.enumerated()), id: \.offset) { _, emoji in
                        Text(emoji)
                            .font(.system(size: 21))
                            .frame(width: 38, height: 38)
                            .background(RoundedRectangle(cornerRadius: 11)
                                .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                    }
                }
                .padding(.top, 6)
            }

            Text("\(preview.signCount) \(preview.signCount == 1 ? "sign" : "signs") · \(preview.memberCount) \(preview.memberCount == 1 ? "member" : "members")")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
    }

    private func joinTapped() {
        isJoining = true
        Task {
            do {
                let boardId = try await boardVM.join(inviteCode: inviteCode)
                if let board = boardVM.boards.first(where: { $0.id == boardId }) {
                    boardVM.selectBoard(board)
                    boardVM.selectedBoard = board
                }
                PendingJoin.shared.clear()
                dismiss()
            } catch {
                loadError = error.localizedDescription
                isJoining = false
            }
        }
    }
}
