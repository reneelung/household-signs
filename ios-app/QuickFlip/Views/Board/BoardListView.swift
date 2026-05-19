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
                    .background(Color.white)
                    .border(Color.appBorder, width: 1)

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
                                NavigationLink(destination: {
                                    BoardView(authVM: authVM, boardVM: boardVM, signsVM: signsVM)
                                        .onAppear {
                                            boardVM.selectBoard(board)
                                        }
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
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationBarHidden(true)
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
