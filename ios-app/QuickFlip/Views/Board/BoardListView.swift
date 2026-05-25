import SwiftUI

struct BoardListView: View {
    @Bindable var authVM: AuthViewModel
    @Bindable var boardVM: BoardViewModel
    let signsVM: SignsViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("QuickFlip")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.appText)

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
                                .font(.system(size: 18))
                                .foregroundColor(.appSecondary)
                        }
                    }
                    .padding(20)
                    .background(.thinMaterial)

                    if boardVM.isLoadingMembership {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if boardVM.boards.isEmpty {
                        emptyStateView
                    } else {
                        List {
                            ForEach(boardVM.boards) { board in
                                let member = boardVM.boardMembers.first { $0.boardId == board.id }
                                Button(action: {
                                    boardVM.selectBoard(board)
                                    boardVM.selectedBoard = board
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(board.name)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.appText)

                                        if let member = member {
                                            Text(member.role.capitalized)
                                                .font(.system(size: 13))
                                                .foregroundColor(.appSecondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        Task {
                                            await boardVM.deleteBoard(board)
                                        }
                                    } label: {
                                        Image(systemName: "trash.fill")
                                            .font(.system(size: 20))
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(Circle().fill(Color.red))
                                            .foregroundColor(.white)
                                    }

                                    Button(role: .cancel) {
                                        boardVM.boardModalMode = .create
                                        boardVM.inputText = board.name
                                        boardVM.errorMessage = ""
                                        boardVM.showBoardModal = true
                                    } label: {
                                        Image(systemName: "square.and.pencil")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .navigationDestination(item: $boardVM.selectedBoard) { _ in
                            BoardView(authVM: authVM, boardVM: boardVM, signsVM: signsVM)
                        }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        boardVM.boardModalMode = .create
                        boardVM.inputText = ""
                        boardVM.errorMessage = ""
                        boardVM.showBoardModal = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .sheet(isPresented: $boardVM.showBoardModal) {
                BoardModal(boardVM: boardVM)
            }
            .task {
                if let userId = authVM.user?.id {
                    await boardVM.checkMembership(userId: UUID(uuidString: userId.uuidString) ?? UUID())
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 12) {
                Text("No Boards Yet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.appText)

                Text("Create a board or join one with an invite code")
                    .font(.system(size: 15))
                    .foregroundColor(.appSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button(action: {
                    boardVM.boardModalMode = .create
                    boardVM.inputText = ""
                    boardVM.errorMessage = ""
                    boardVM.showBoardModal = true
                }) {
                    Text("Create a Board")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.appAccent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: {
                    boardVM.boardModalMode = .join
                    boardVM.inputText = ""
                    boardVM.errorMessage = ""
                    boardVM.showBoardModal = true
                }) {
                    Text("Join with Code")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .foregroundColor(.appAccent)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appAccent, lineWidth: 2))
                }
            }
            .padding(.horizontal, 20)

            Spacer()
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
