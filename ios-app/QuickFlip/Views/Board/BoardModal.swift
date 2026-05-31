import SwiftUI

struct BoardModal: View {
    @Bindable var boardVM: BoardViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header with X and checkmark
                    ZStack {
                        Text(boardVM.boardModalMode == .create ? "Create Board" : "Join Board")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appText)

                        HStack {
                            Button(action: {
                                boardVM.setAsDefault = false
                                dismiss()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.appText)
                                    .frame(width: 44, height: 44)
                                    .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                                    .glassEffect(.regular, in: .circle)
                            }

                            Spacer()

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
                                    ProgressView().tint(.appText)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.appText)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color(uiColor: .secondarySystemFill)))
                            .glassEffect(.regular, in: .circle)
                            .disabled(boardVM.isLoading || boardVM.inputText.isEmpty)
                        }
                    }
                    .padding(16)

                    ScrollView {
                        VStack(spacing: 28) {
                            // Text input section
                            VStack(spacing: 12) {
                                TextField(
                                    boardVM.boardModalMode == .create ? "Board Name" : "Invite Code",
                                    text: $boardVM.inputText
                                )
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.appText)
                                .padding(12)
                                .frame(minHeight: 56)
                                .background(Color(uiColor: .secondarySystemBackground))
                                .cornerRadius(16)

                                if boardVM.boardModalMode == .create {
                                    Toggle(isOn: $boardVM.setAsDefault) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Set as default")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(.appText)
                                            Text("Open this board when you launch the app.")
                                                .font(.system(size: 12))
                                                .foregroundColor(.appSecondary)
                                        }
                                    }
                                    .padding(12)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .cornerRadius(16)
                                }
                            }

                            // Error message
                            if !boardVM.errorMessage.isEmpty {
                                Text(boardVM.errorMessage)
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
    BoardModal(boardVM: BoardViewModel())
}
