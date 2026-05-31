import SwiftUI

struct InviteSheet: View {
    let board: Board
    @Bindable var boardVM: BoardViewModel
    @Bindable var authVM: AuthViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var inviteCode: String?
    @State private var loadError: String?
    @State private var showingEmailComposer = false
    @State private var resetConfirm = false
    @State private var isResetting = false

    private let yellow = Color(hex: "FFD600")
    private var isDark: Bool { colorScheme == .dark }
    private var members: [BoardMember] { boardVM.getMembers(for: board) }
    private var signs: [Sign] { boardVM.getSigns(for: board) }
    private var isOwner: Bool { boardVM.isOwner(of: board) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                signPreview
                VStack(alignment: .leading, spacing: 2) {
                    Text("INVITING TO")
                        .font(.system(size: 11, weight: .bold))
                        .kerning(1)
                        .foregroundStyle(.secondary)
                    Text(board.name)
                        .font(.system(size: 22, weight: .heavy))
                        .kerning(-0.6)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)

            HStack(spacing: 10) {
                shareButton
                emailButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)

            if let error = loadError {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }

            Text("Members (\(members.count))")
                .font(.system(size: 11, weight: .bold))
                .kerning(1)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(members) { member in
                        MemberRow(
                            member: member,
                            isOwner: member.role == "owner",
                            isYou: member.userId == currentUserId
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        Divider().padding(.leading, 64)
                    }
                }
            }

            if isOwner {
                Button {
                    resetConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        if isResetting {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                        Text("Reset link")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(isResetting || inviteCode == nil)
                .padding(.vertical, 14)
            }
        }
        .background(Color.clear.background(.regularMaterial))
        .sheet(isPresented: $showingEmailComposer) {
            if let code = inviteCode {
                MailComposeView(url: boardVM.inviteURL(for: code), groupName: board.name)
            }
        }
        .task {
            do {
                inviteCode = try await boardVM.activeInviteCode(for: board)
            } catch {
                loadError = "Could not load invite link: \(error.localizedDescription)"
            }
        }
        .confirmationDialog(
            "Reset invite link?",
            isPresented: $resetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset Link", role: .destructive) {
                isResetting = true
                Task {
                    do {
                        inviteCode = try await boardVM.resetInviteCode(for: board)
                    } catch {
                        loadError = "Could not reset link: \(error.localizedDescription)"
                    }
                    isResetting = false
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This invalidates the current link. Anyone you've shared it with who hasn't joined yet won't be able to.")
        }
    }

    private var currentUserId: UUID? {
        guard let raw = authVM.user?.id.uuidString else { return nil }
        return UUID(uuidString: raw)
    }

    @ViewBuilder
    private var shareButton: some View {
        if let code = inviteCode {
            ShareLink(item: boardVM.inviteURL(for: code)) {
                shareLinkLabel
            }
            .buttonStyle(.plain)
        } else {
            shareLinkLabel
                .opacity(0.5)
                .overlay(ProgressView().tint(.black))
        }
    }

    private var shareLinkLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "link")
            Text("Share link").fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Capsule().fill(yellow))
        .foregroundStyle(.black)
        .shadow(color: yellow.opacity(0.35), radius: 12, y: 6)
    }

    private var emailButton: some View {
        Button {
            showingEmailComposer = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "envelope")
                Text("Email").fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule().fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
            )
            .foregroundStyle(.primary)
        }
        .buttonStyle(.plain)
        .disabled(inviteCode == nil)
    }

    private var signPreview: some View {
        let emojis = signs.prefix(4).map(\.emoji)
        return LazyVGrid(
            columns: [GridItem(.fixed(26), spacing: 3),
                      GridItem(.fixed(26), spacing: 3)],
            spacing: 3
        ) {
            ForEach(Array(emojis.enumerated()), id: \.offset) { _, e in
                Text(e)
                    .font(.system(size: 15))
                    .frame(width: 26, height: 26)
                    .background(
                        RoundedRectangle(cornerRadius: 7)
                            .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05))
                    )
            }
        }
        .frame(width: 55)
    }
}
