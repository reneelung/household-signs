import SwiftUI

struct BoardListView: View {
    @Bindable var authVM: AuthViewModel
    @Bindable var boardVM: BoardViewModel
    let signsVM: SignsViewModel

    @State private var editingBoard: Board?
    @State private var deletingBoard: Board?
    @State private var leavingBoard: Board?
    @State private var invitingTo: Board?
    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var showProfile = false
    @State private var confirmingSignOut = false
    @Environment(\.colorScheme) private var colorScheme

    private var sortedBoards: [Board] {
        boardVM.boards.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.createdAt > rhs.createdAt
        }
    }



    var body: some View {
        NavigationStack {
            ZStack {
                AmbientBackdrop(palette: .cool)

                if boardVM.isLoadingMembership {
                    ProgressView().tint(.white)
                } else if boardVM.boards.isEmpty {
                    EmptyBoardListView()
                } else {
                    boardsList
                }

                VStack(spacing: 0) {
                    HStack {
                        Text("My Groups")
                            .font(.system(size: 28, weight: .bold))
                            .kerning(-0.5)
                            .foregroundColor(.white)

                        Spacer()

                        AvatarMenuButton(
                            authVM: authVM,
                            showSettings: $showSettings,
                            showNotifications: $showNotifications,
                            showProfile: $showProfile,
                            confirmingSignOut: $confirmingSignOut
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(colorScheme == .dark ? 0.55 : 0.20),
                                Color.black.opacity(0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea(edges: .top)
                    )

                    Spacer()
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        AddSignFAB {
                            boardVM.boardModalMode = .create
                            boardVM.inputText = ""
                            boardVM.errorMessage = ""
                            boardVM.showBoardModal = true
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $boardVM.showBoardModal) {
                BoardModal(boardVM: boardVM)
            }
            .sheet(item: $editingBoard) { board in
                EditBoardView(board: board, boardVM: boardVM)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(authVM: authVM)
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView()
            }
            .sheet(isPresented: $showProfile) {
                ProfileView(authVM: authVM)
            }
            .sheet(item: $invitingTo) { board in
                InviteSheet(board: board, boardVM: boardVM, authVM: authVM)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog(
                "Sign out?",
                isPresented: $confirmingSignOut,
                titleVisibility: .visible
            ) {
                Button("Sign out", role: .destructive) {
                    Task {
                        await authVM.signOut()
                        boardVM.boardId = nil
                        boardVM.boards = []
                        boardVM.boardMembers = []
                        boardVM.signsByBoard = [:]
                        boardVM.selectedBoard = nil
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You'll need to sign in again to see your groups.")
            }
            .confirmationDialog(
                deletingBoard.map { "Delete \"\($0.name)\"?" } ?? "",
                isPresented: Binding(
                    get: { deletingBoard != nil },
                    set: { if !$0 { deletingBoard = nil } }
                ),
                presenting: deletingBoard
            ) { board in
                Button("Delete \(board.name)", role: .destructive) {
                    Task { await boardVM.deleteBoard(board) }
                }
                Button("Cancel", role: .cancel) { }
            } message: { board in
                Text("This removes \(board.name) for everyone in the group. It can't be undone.")
            }
            .confirmationDialog(
                leavingBoard.map { "Leave \"\($0.name)\"?" } ?? "",
                isPresented: Binding(
                    get: { leavingBoard != nil },
                    set: { if !$0 { leavingBoard = nil } }
                ),
                presenting: leavingBoard
            ) { board in
                Button("Leave \(board.name)", role: .destructive) {
                    Task { await boardVM.leave(board) }
                }
                Button("Cancel", role: .cancel) { }
            } message: { board in
                Text("You'll be removed from \(board.name). Other members keep access.")
            }
            .navigationDestination(item: $boardVM.selectedBoard) { _ in
                BoardView(authVM: authVM, boardVM: boardVM, signsVM: signsVM)
            }
            .task {
                if let userId = authVM.user?.id {
                    await boardVM.checkMembership(userId: UUID(uuidString: userId.uuidString) ?? UUID())
                }
            }
        }
    }

    private var boardsList: some View {
        List {
            ForEach(sortedBoards) { board in
                let isOwner = boardVM.isOwner(of: board)
                Button {
                    boardVM.selectBoard(board)
                    boardVM.selectedBoard = board
                } label: {
                    BoardRowView(
                        board: board,
                        isOwner: isOwner,
                        members: boardVM.getMembers(for: board),
                        signs: boardVM.getSigns(for: board)
                    )
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 5, leading: 18, bottom: 5, trailing: 18))
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deletingBoard = board
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button {
                        editingBoard = board
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .contextMenu {
                    Button {
                        Task { await boardVM.togglePin(board) }
                    } label: {
                        Label(board.isPinned ? "Unpin" : "Pin to top",
                              systemImage: board.isPinned ? "pin.slash" : "pin")
                    }

                    Divider()

                    Button {
                        invitingTo = board
                    } label: {
                        Label("Members & Invites", systemImage: "person.2")
                    }

                    Divider()

                    Button {
                        editingBoard = board
                    } label: {
                        Label("Edit Group", systemImage: "pencil")
                    }

                    if !isOwner {
                        Button {
                            leavingBoard = board
                        } label: {
                            Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }

                    Divider()

                    Button(role: .destructive) {
                        deletingBoard = board
                    } label: {
                        Label("Delete Group", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 76, for: .scrollContent)
        .contentMargins(.bottom, 90, for: .scrollContent)
    }
}

private struct EmptyBoardListView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("No groups yet")
            .font(.system(size: 17, weight: .medium))
            .kerning(-0.2)
            .foregroundStyle(colorScheme == .dark
                ? Color.white.opacity(0.40)
                : Color(hex: "0F1115").opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct BoardRowView: View {
    let board: Board
    let isOwner: Bool
    let members: [BoardMember]
    let signs: [Sign]

    @Environment(\.colorScheme) private var colorScheme

    private let yellow = Color(hex: "FFD600")
    private let rowRadius: CGFloat = 22
    private var isDark: Bool { colorScheme == .dark }
    private var activeSignCount: Int { signs.filter { $0.active }.count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        if board.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(textMuted)
                                .rotationEffect(.degrees(45))
                        }

                        Text(board.name)
                            .font(.system(size: 19, weight: .bold))
                            .kerning(-0.5)
                            .lineLimit(1)

                        if !isOwner {
                            Text("MEMBER")
                                .font(.system(size: 10, weight: .bold))
                                .kerning(0.6)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(isDark
                                    ? Color.white.opacity(0.10)
                                    : Color.black.opacity(0.06)))
                                .foregroundStyle(textMuted)
                        }
                    }

                    Text(metaLine)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(textMuted)
                        .lineLimit(1)
                }

                Spacer()

                if activeSignCount > 0 {
                    HStack(spacing: 4) {
                        Circle().fill(.black).frame(width: 5, height: 5)
                        Text("\(activeSignCount)")
                    }
                    .font(.system(size: 10, weight: .heavy))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(yellow))
                    .foregroundStyle(.black)
                    .shadow(color: yellow.opacity(0.45), radius: 6, y: 0)
                }
            }

            HStack(spacing: 12) {
                if !signs.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(signs.prefix(5)) { sign in
                            Text(sign.emoji)
                                .font(.system(size: 17))
                                .frame(width: 30, height: 30)
                                .background(RoundedRectangle(cornerRadius: 9).fill(chipFill))
                        }
                        if signs.count > 5 {
                            Text("+\(signs.count - 5)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(textMuted)
                                .padding(.horizontal, 9)
                                .frame(height: 30)
                                .background(RoundedRectangle(cornerRadius: 9).fill(chipFill))
                        }
                    }
                }

                Spacer(minLength: 0)

                MemberAvatarStack(members: members)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowSurface)
        .overlay(
            RoundedRectangle(cornerRadius: rowRadius)
                .strokeBorder(borderColor, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(isDark ? 0.28 : 0.10),
                radius: isDark ? 22 : 24, y: isDark ? 8 : 10)
        .shadow(color: isDark ? .clear : .black.opacity(0.05),
                radius: 6, y: 2)
    }

    @ViewBuilder
    private var rowSurface: some View {
        if #available(iOS 26, *) {
            RoundedRectangle(cornerRadius: rowRadius)
                .fill(isDark ? Color.white.opacity(0.075) : Color.white.opacity(0.88))
                .glassEffect(in: .rect(cornerRadius: rowRadius))
        } else if #available(iOS 17, *) {
            RoundedRectangle(cornerRadius: rowRadius)
                .fill(isDark ? Color.clear : Color.white.opacity(0.40))
                .background(.regularMaterial, in: .rect(cornerRadius: rowRadius))
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(isDark
                      ? Color(uiColor: .secondarySystemBackground)
                      : Color.white)
        }
    }

    private var chipFill: Color {
        isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.04)
    }

    private var borderColor: Color {
        isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.06)
    }

    private var textMuted: Color {
        isDark ? Color.white.opacity(0.55) : Color(hex: "0F1115").opacity(0.55)
    }

    private var metaLine: String {
        let memberWord = members.count == 1 ? "member" : "members"
        return "\(members.count) \(memberWord)"
    }
}

private struct MemberAvatarStack: View {
    let members: [BoardMember]
    @Environment(\.colorScheme) private var colorScheme

    private let maxVisible = 4
    private let size: CGFloat = 22

    var body: some View {
        let visible = Array(members.prefix(maxVisible))
        let overflow = max(0, members.count - maxVisible)
        HStack(spacing: -6) {
            ForEach(visible) { member in
                MemberAvatarBubble(name: member.displayName ?? "?", size: size)
                    .overlay(Circle().stroke(borderColor, lineWidth: 1.5))
            }
            if overflow > 0 {
                Text("+\(overflow)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background(Circle().fill(Color.white.opacity(0.14)))
                    .overlay(Circle().stroke(borderColor, lineWidth: 1.5))
            }
        }
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color(hex: "15151A") : .white
    }
}

private struct EditBoardView: View {
    let board: Board
    @Bindable var boardVM: BoardViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                        }

                        Spacer()

                        Text("Edit Group")
                            .font(.system(size: 18, weight: .semibold))

                        Spacer()

                        Button(action: {
                            Task {
                                // TODO: implement update board
                                dismiss()
                            }
                        }) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                        }
                        .disabled(name.isEmpty || isLoading)
                    }
                    .padding(16)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Group Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)

                            TextField("Group name", text: $name)
                                .font(.system(size: 18, weight: .regular))
                                .padding(12)
                                .frame(minHeight: 56)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(16)
                        }

                        Spacer()
                    }
                    .padding(16)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                name = board.name
            }
        }
    }
}

private struct AddSignFAB: View {
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
        .accessibilityLabel("Create new group")
    }
}


#Preview {
    BoardListView(
        authVM: AuthViewModel(),
        boardVM: BoardViewModel(),
        signsVM: SignsViewModel()
    )
}
