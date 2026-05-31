import SwiftUI

struct BoardView: View {
    @Bindable var authVM: AuthViewModel
    @Bindable var boardVM: BoardViewModel
    @Bindable var signsVM: SignsViewModel
    @State private var showingAddSheet = false
    @State private var editingSign: Sign?
    @State private var deletingSign: Sign?
    @State private var showSettings = false
    @State private var showNotifications = false
    @State private var showProfile = false
    @State private var confirmingSignOut = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AmbientBackdrop(palette: .cool)

            VStack(spacing: 0) {
                HStack {
                    Text(boardVM.boardName)
                        .font(.system(size: 34, weight: .bold))
                        .kerning(-1.1)
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
                .padding(.top, 12)
                .padding(.bottom, 22)

                if signsVM.signs.isEmpty {
                    EmptyBoardView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(Array(signsVM.signs.enumerated()), id: \.element.id) { idx, sign in
                                SignCardView(
                                    sign: sign,
                                    userNickname: authVM.user?.userMetadata["display_name"]?.stringValue ?? "Unknown",
                                    signsVM: signsVM,
                                    onEdit: { editingSign = sign },
                                    onDelete: { deletingSign = sign },
                                    index: idx
                                )
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 100)
                    }
                }
            }

            AddSignFAB { showingAddSheet = true }
                .padding(.trailing, 20)
                .padding(.bottom, 28)
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSignModal(signsVM: signsVM, authVM: authVM)
        }
        .sheet(item: $editingSign) { sign in
            EditSignView(sign: sign, signsVM: signsVM)
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
            "Delete this sign?",
            isPresented: Binding(
                get: { deletingSign != nil },
                set: { if !$0 { deletingSign = nil } }
            ),
            presenting: deletingSign
        ) { sign in
            Button("Delete \(sign.label)", role: .destructive) {
                Task {
                    await signsVM.deleteSign(sign)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .task {
            if let boardId = boardVM.boardId {
                await signsVM.loadSigns(for: boardId)
            }
        }
        .onDisappear {
            signsVM.cleanup()
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
        .accessibilityLabel("Add sign")
    }
}

private struct EmptyBoardView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Text("No status cards yet")
            .font(.system(size: 17, weight: .medium))
            .kerning(-0.2)
            .foregroundStyle(colorScheme == .dark
                ? Color.white.opacity(0.40)
                : Color(hex: "0F1115").opacity(0.45))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct EditSignView: View {
    let sign: Sign
    @Bindable var signsVM: SignsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var label: String
    @State private var selectedEmoji: String
    @State private var stateOffLabel: String
    @State private var stateOnLabel: String

    init(sign: Sign, signsVM: SignsViewModel) {
        self.sign = sign
        self.signsVM = signsVM
        _label = State(initialValue: sign.label)
        _selectedEmoji = State(initialValue: sign.emoji)
        _stateOffLabel = State(initialValue: sign.stateOffLabel)
        _stateOnLabel = State(initialValue: sign.stateOnLabel)
    }

    private var isFormValid: Bool {
        !label.isEmpty && !stateOffLabel.isEmpty && !stateOnLabel.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    ZStack {
                        Text("Edit Sign")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appText)

                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.appText)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                            }

                            Spacer()

                            Button(action: {
                                Task {
                                    await signsVM.updateSign(
                                        id: sign.id,
                                        label: label,
                                        emoji: selectedEmoji,
                                        stateOffLabel: stateOffLabel,
                                        stateOnLabel: stateOnLabel
                                    )
                                    dismiss()
                                }
                            }) {
                                if signsVM.isLoading {
                                    ProgressView().tint(.appText)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.appText)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                            .disabled(!isFormValid || signsVM.isLoading)
                        }
                    }
                    .padding(16)

                    ScrollView {
                        VStack(spacing: 28) {
                            VStack(spacing: 12) {
                                Text("Choose Emoji")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                EmojiPickerView(selectedEmoji: $selectedEmoji)
                            }

                            VStack(spacing: 12) {
                                Text("Sign Name")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("e.g., Dishwasher", text: $label)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.appText)
                                    .padding(12)
                                    .frame(minHeight: 56)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(16)
                                    .onChange(of: label) { _, newValue in
                                        if newValue.count > 20 {
                                            label = String(newValue.prefix(20))
                                        }
                                    }
                            }

                            VStack(spacing: 12) {
                                Text("Off State Label")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("e.g., Dirty", text: $stateOffLabel)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.appText)
                                    .padding(12)
                                    .frame(minHeight: 56)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(16)
                                    .onChange(of: stateOffLabel) { _, newValue in
                                        if newValue.count > 16 {
                                            stateOffLabel = String(newValue.prefix(16))
                                        }
                                    }
                            }

                            VStack(spacing: 12) {
                                Text("On State Label")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("e.g., Clean", text: $stateOnLabel)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.appText)
                                    .padding(12)
                                    .frame(minHeight: 56)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(16)
                                    .onChange(of: stateOnLabel) { _, newValue in
                                        if newValue.count > 16 {
                                            stateOnLabel = String(newValue.prefix(16))
                                        }
                                    }
                            }

                            if !signsVM.errorMessage.isEmpty {
                                Text(signsVM.errorMessage)
                                    .font(.system(size: 13))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16)
                            }

                            Spacer()
                        }
                        .padding(16)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    BoardView(
        authVM: AuthViewModel(),
        boardVM: BoardViewModel(),
        signsVM: SignsViewModel()
    )
}
