import SwiftUI

struct BoardModal: View {
    @Bindable var boardVM: BoardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text(boardVM.boardModalMode == .create ? "Create Board" : "Join Board")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appText)

                        Spacer()

                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.appSecondary)
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .border(Color.appBorder, width: 1)

                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Text(boardVM.boardModalMode == .create ? "Board Name" : "Invite Code")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.appSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            TextField(
                                boardVM.boardModalMode == .create ? "e.g., My Family" : "8-digit code",
                                text: $boardVM.inputText
                            )
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                        }

                        if !boardVM.errorMessage.isEmpty {
                            Text(boardVM.errorMessage)
                                .font(.system(size: 13))
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                        }

                        Button(action: {
                            Task {
                                if boardVM.boardModalMode == .create {
                                    await boardVM.createBoard()
                                } else {
                                    await boardVM.joinBoard()
                                }
                            }
                        }) {
                            if boardVM.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(boardVM.boardModalMode == .create ? "Create" : "Join")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.appAccent)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .disabled(boardVM.isLoading || boardVM.inputText.isEmpty)

                        Spacer()
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    BoardModal(boardVM: BoardViewModel())
}
