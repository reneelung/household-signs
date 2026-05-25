import SwiftUI

struct BoardSelectionView: View {
    @Bindable var boardVM: BoardViewModel

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    Text("📋")
                        .font(.system(size: 48))

                    Text("No Board Yet")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.appText)

                    Text("Create a new board or join one with an invite code.")
                        .font(.system(size: 15))
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)

                VStack(spacing: 12) {
                    Button(action: {
                        boardVM.resetModal()
                        boardVM.boardModalMode = .create
                        boardVM.showBoardModal = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("Create a Board")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.appAccent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Button(action: {
                        boardVM.resetModal()
                        boardVM.boardModalMode = .join
                        boardVM.showBoardModal = true
                    }) {
                        HStack {
                            Image(systemName: "qrcode")
                            Text("Join with Invite Code")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.appBorder)
                        .foregroundColor(.appText)
                        .cornerRadius(8)
                    }
                }
                .padding(20)

                Spacer()
            }
        }
        .sheet(isPresented: $boardVM.showBoardModal) {
            BoardModal(boardVM: boardVM)
        }
    }
}

#Preview {
    BoardSelectionView(boardVM: BoardViewModel())
}
