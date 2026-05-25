import SwiftUI

struct BoardView: View {
    @Bindable var authVM: AuthViewModel
    @Bindable var boardVM: BoardViewModel
    @Bindable var signsVM: SignsViewModel
    @State private var showDeleteAlert = false
    @State private var signToDelete: Sign?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(boardVM.boardName)
                            .font(boardVM.boardName.count > 20 ? .system(size: 20, weight: .semibold) : .system(size: 28, weight: .semibold))
                            .lineLimit(2)
                            .foregroundColor(.appText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: {
                        Task {
                            await authVM.signOut()
                            boardVM.boardId = nil
                            boardVM.boardName = ""
                            signsVM.signs = []
                            signsVM.cleanup()
                        }
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 16))
                            .foregroundColor(.appText)
                    }
                }
                .padding(20)
                .safeAreaInset(edge: .top) {
                    Color.appBg.frame(height: 0)
                }

                ScrollView {
                    VStack(spacing: 16) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(Array(signsVM.signs.enumerated()), id: \.element.id) { index, sign in
                                SignCardView(
                                    sign: sign,
                                    userNickname: authVM.user?.userMetadata["display_name"]?.stringValue ?? "Unknown",
                                    signsVM: signsVM,
                                    onDelete: {
                                        signToDelete = sign
                                        showDeleteAlert = true
                                    },
                                    index: index
                                )
                            }

                            Button(action: {
                                signsVM.showAddModal = true
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 24, weight: .semibold))
                                    Text("Add Sign")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 120)
                                .foregroundColor(.appSecondary)
                                .border(Color.appBorder, width: 2)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                                        .foregroundColor(.appSecondary)
                                )
                            }
                        }
                        .padding(12)
                    }
                }
            }
        }
        .sheet(isPresented: $signsVM.showAddModal) {
            AddSignModal(signsVM: signsVM)
        }
        .alert("Delete Sign?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let sign = signToDelete {
                    Task {
                        await signsVM.deleteSign(sign)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let sign = signToDelete {
                Text("Are you sure you want to delete \(sign.label)?")
            }
        }
        .task {
            if let boardId = boardVM.boardId {
                await signsVM.loadSigns(for: boardId)
            }
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
