import SwiftUI

@main
struct QuickFlipApp: App {
    @State private var authVM = AuthViewModel()
    @State private var boardVM = BoardViewModel()
    @State private var signsVM = SignsViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                Color.appBg.ignoresSafeArea()

                switch authVM.authStep {
                case .loading:
                    ProgressView()
                        .tint(.appAccent)

                case .auth:
                    AuthView(authVM: authVM)

                case .nickname:
                    NicknameView(authVM: authVM)

                case .done:
                    if boardVM.isLoadingMembership {
                        ProgressView()
                            .tint(.appAccent)
                    } else if boardVM.boardId == nil {
                        BoardSelectionView(boardVM: boardVM)
                    } else {
                        BoardView(
                            authVM: authVM,
                            boardVM: boardVM,
                            signsVM: signsVM
                        )
                    }
                }
            }
            .onChange(of: authVM.authStep) { _, newStep in
                if newStep == .done, let userId = authVM.user?.id {
                    Task {
                        await boardVM.checkMembership(userId: userId)
                    }
                }
            }
        }
    }
}
