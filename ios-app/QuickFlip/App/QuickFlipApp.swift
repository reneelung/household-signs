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
                    VStack {
                        ProgressView()
                            .tint(.appAccent)
                        Text("Loading...")
                            .foregroundColor(.appText)
                            .padding(.top, 16)
                    }

                case .auth:
                    AuthView(authVM: authVM)

                case .nickname:
                    NicknameView(authVM: authVM)

                case .done:
                    BoardListView(
                        authVM: authVM,
                        boardVM: boardVM,
                        signsVM: signsVM
                    )
                }
            }
        }
    }
}

