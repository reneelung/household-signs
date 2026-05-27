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
                        Label("Invite people", systemImage: "person.crop.circle.badge.plus")
                    }
                    Button {
                        invitingTo = board
                    } label: {
                        Label("Members", systemImage: "person.2")
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

struct AvatarMenuButton: View {
    @Bindable var authVM: AuthViewModel
    @Binding var showSettings: Bool
    @Binding var showNotifications: Bool
    @Binding var confirmingSignOut: Bool

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Menu {
            Section {
                Text(authVM.displayName)
                if !authVM.accountEmail.isEmpty {
                    Text(authVM.accountEmail).font(.footnote)
                }
            }

            Section {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Button {
                    showNotifications = true
                } label: {
                    Label("Notifications", systemImage: "bell")
                }
            }

            Section {
                Button(role: .destructive) {
                    confirmingSignOut = true
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            avatarPill
        }
        .menuOrder(.fixed)
        .accessibilityLabel("Account")
    }

    private var avatarPill: some View {
        Text(authVM.initial)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(isDark ? Color.white : Color(hex: "0F1115"))
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.08))
            )
            .overlay(
                Circle()
                    .strokeBorder(isDark ? Color.white.opacity(0.20) : Color.black.opacity(0.10),
                                  lineWidth: 0.5)
            )
            .contentShape(Circle())
    }
}

struct SettingsView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Name", value: authVM.displayName)
                    LabeledContent("Email", value: authVM.accountEmail)
                }
                Section("Appearance") {
                    Picker("Theme", selection: .constant("Automatic")) {
                        Text("Automatic").tag("Automatic")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var newSign = true
    @State private var signFlipped = true
    @State private var memberJoined = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    Toggle("New sign added", isOn: $newSign)
                    Toggle("Sign flipped", isOn: $signFlipped)
                    Toggle("Member joined", isOn: $memberJoined)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
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

struct MemberAvatarBubble: View {
    let name: String
    let size: CGFloat

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
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(color))
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

// MARK: - Invite flow

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

            Text("\(members.count) \(members.count == 1 ? "Member" : "Members")")
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

            Text(preview.board.name)
                .font(.system(size: 38, weight: .heavy))
                .kerning(-1.4)
                .padding(.top, 2)

            if !preview.signs.isEmpty {
                HStack(spacing: 6) {
                    ForEach(preview.signs.prefix(5)) { sign in
                        Text(sign.emoji)
                            .font(.system(size: 21))
                            .frame(width: 38, height: 38)
                            .background(RoundedRectangle(cornerRadius: 11)
                                .fill(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.05)))
                    }
                }
                .padding(.top, 6)
            }

            Text("\(preview.signs.count) \(preview.signs.count == 1 ? "sign" : "signs") · \(preview.members.count) \(preview.members.count == 1 ? "member" : "members")")
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

// MARK: - Mail composer bridge

import MessageUI
import UIKit

struct MailComposeView: UIViewControllerRepresentable {
    let url: URL
    let groupName: String

    func makeUIViewController(context: Context) -> UIViewController {
        if MFMailComposeViewController.canSendMail() {
            let vc = MFMailComposeViewController()
            vc.mailComposeDelegate = context.coordinator
            vc.setSubject("Join \(groupName) on QuickFlip")
            vc.setMessageBody(
                """
                I'd like you to join my \(groupName) group on QuickFlip.

                Tap to join: \(url.absoluteString)

                QuickFlip is a shared-status app for things like the dishwasher, laundry, and door.
                """,
                isHTML: false
            )
            return vc
        } else {
            // Mail not configured — open the system mailto: URL.
            let subject = "Join \(groupName) on QuickFlip".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let body = "Tap to join: \(url.absoluteString)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let mailto = URL(string: "mailto:?subject=\(subject)&body=\(body)") {
                DispatchQueue.main.async {
                    UIApplication.shared.open(mailto)
                }
            }
            return UIViewController()
        }
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            controller.dismiss(animated: true)
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
