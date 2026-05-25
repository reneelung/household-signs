import SwiftUI

struct BoardListView: View {
    @Bindable var authVM: AuthViewModel
    @Bindable var boardVM: BoardViewModel
    let signsVM: SignsViewModel

    @State private var editingBoard: Board?
    @State private var deletingBoard: Board?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                AmbientBackdrop(palette: .cool)

                VStack(spacing: 0) {
                    HStack {
                        Text("My Groups")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        Button(action: {
                            Task {
                                await authVM.signOut()
                                boardVM.boardId = nil
                                boardVM.boards = []
                                boardVM.boardMembers = []
                            }
                        }) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)

                    Group {
                        if boardVM.isLoadingMembership {
                            VStack {
                                ProgressView()
                                    .tint(.white)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if boardVM.boards.isEmpty {
                            EmptyBoardListView(boardVM: boardVM)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 10) {
                                    ForEach(boardVM.boards) { board in
                                        let member = boardVM.boardMembers.first { $0.boardId == board.id }
                                        NavigationLink(value: board) {
                                            BoardRowView(
                                                board: board,
                                                userRole: member?.role ?? "member",
                                                memberCount: boardVM.boardMembers.filter { $0.boardId == board.id }.count
                                            )
                                        }
                                        .buttonStyle(.plain)
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
                                                editingBoard = board
                                            } label: {
                                                Label("Edit board", systemImage: "pencil")
                                            }
                                            if member?.role == "member" {
                                                Button(role: .destructive) {
                                                    Task {
                                                        // TODO: implement leave board
                                                    }
                                                } label: {
                                                    Label("Leave board", systemImage: "rectangle.portrait.and.arrow.right")
                                                }
                                            } else {
                                                Button(role: .destructive) {
                                                    deletingBoard = board
                                                } label: {
                                                    Label("Delete board", systemImage: "trash")
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 18)
                                .padding(.top, 8)
                                .padding(.bottom, 100)
                            }
                            .navigationDestination(for: Board.self) { board in
                                BoardView(authVM: authVM, boardVM: boardVM, signsVM: signsVM)
                                    .onAppear {
                                        boardVM.selectBoard(board)
                                    }
                            }
                        }
                    }
                }

                AddBoardFAB {
                    boardVM.boardModalMode = .create
                    boardVM.inputText = ""
                    boardVM.errorMessage = ""
                    boardVM.showBoardModal = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $boardVM.showBoardModal) {
                BoardModal(boardVM: boardVM)
            }
            .sheet(item: $editingBoard) { board in
                EditBoardView(board: board, boardVM: boardVM)
            }
            .confirmationDialog(
                deletingBoard.map { "Delete \"\($0.name)\"?" } ?? "",
                isPresented: Binding(
                    get: { deletingBoard != nil },
                    set: { if !$0 { deletingBoard = nil } }
                ),
                presenting: deletingBoard
            ) { board in
                Button("Delete board", role: .destructive) {
                    Task {
                        await boardVM.deleteBoard(board)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: { _ in
                Text("This removes the board for everyone. This can't be undone.")
            }
            .task {
                if let userId = authVM.user?.id {
                    await boardVM.checkMembership(userId: UUID(uuidString: userId.uuidString) ?? UUID())
                }
            }
        }
    }
}

private struct EmptyBoardListView: View {
    @Bindable var boardVM: BoardViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 12) {
                Text("No boards yet")
                    .font(.system(size: 17, weight: .medium))
                    .kerning(-0.2)
                    .foregroundStyle(.white.opacity(0.40))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

private struct BoardRowView: View {
    let board: Board
    let userRole: String
    let memberCount: Int

    @Environment(\.colorScheme) private var colorScheme

    private let rowRadius: CGFloat = 22
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(board.name)
                        .font(.system(size: 19, weight: .bold))
                        .kerning(-0.5)
                        .lineLimit(1)

                    if userRole.lowercased() == "member" {
                        Text("MEMBER")
                            .font(.system(size: 10, weight: .bold))
                            .kerning(0.6)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(isDark
                                    ? Color.white.opacity(0.10)
                                    : Color.black.opacity(0.06))
                            )
                            .foregroundStyle(mutedText)
                    }
                }
                Spacer(minLength: 8)
            }

            Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(mutedText)
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

    private var borderColor: Color {
        isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.06)
    }

    private var mutedText: Color {
        isDark ? Color.white.opacity(0.55) : Color(hex: "0F1115").opacity(0.55)
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

                        Text("Edit Board")
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
                            Text("Board Name")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)

                            TextField("Board name", text: $name)
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

private struct AddBoardFAB: View {
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
        .accessibilityLabel("Create new board")
    }
}

private struct AmbientBackdrop: View {
    enum Palette { case cool, warm, forest, plum }

    var palette: Palette = .cool

    @Environment(\.colorScheme) private var colorScheme

    private let anchors: [(CGFloat, CGFloat)] = [
        (0.18, 0.12), (0.78, 0.30), (0.40, 0.75)
    ]

    private var colors: [Color] {
        let dark = colorScheme == .dark
        switch (palette, dark) {
        case (.cool,   true):  return [Color(hex: "3B5BFF"), Color(hex: "FF4DCB"), Color(hex: "22D3EE")]
        case (.cool,   false): return [Color(hex: "A9C4FF"), Color(hex: "FFB8E3"), Color(hex: "A6ECF4")]
        case (.warm,   true):  return [Color(hex: "FF8A3D"), Color(hex: "FFD600"), Color(hex: "FF3D7F")]
        case (.warm,   false): return [Color(hex: "FFCFA8"), Color(hex: "FFE680"), Color(hex: "FFB8C8")]
        case (.forest, true):  return [Color(hex: "1ED760"), Color(hex: "FFD600"), Color(hex: "3B5BFF")]
        case (.forest, false): return [Color(hex: "B8ECC4"), Color(hex: "FFE680"), Color(hex: "A9C4FF")]
        case (.plum,   true):  return [Color(hex: "9B5BFF"), Color(hex: "FF4DCB"), Color(hex: "FFD600")]
        case (.plum,   false): return [Color(hex: "D4BAFF"), Color(hex: "FFB8E3"), Color(hex: "FFE680")]
        }
    }

    private var baseColor: Color {
        colorScheme == .dark ? .black : Color(hex: "F5F5F7")
    }

    private var washColor: Color {
        colorScheme == .dark
            ? Color.black.opacity(0.45)
            : Color(hex: "EEEEF2").opacity(0.40)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                baseColor
                if #available(iOS 17, *) {
                    ForEach(Array(colors.enumerated()), id: \.offset) { idx, color in
                        Circle()
                            .fill(color)
                            .frame(width: 280, height: 280)
                            .blur(radius: 60)
                            .opacity(colorScheme == .dark ? 0.55 : 0.60)
                            .position(
                                x: geo.size.width  * anchors[idx].0,
                                y: geo.size.height * anchors[idx].1
                            )
                    }
                    washColor
                }
            }
            .ignoresSafeArea()
        }
    }
}

#Preview {
    BoardListView(
        authVM: AuthViewModel(),
        boardVM: BoardViewModel(),
        signsVM: SignsViewModel()
    )
}
