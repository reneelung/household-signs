import SwiftUI

struct EditSignModal: View {
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
                                    .glassEffect(.regular, in: .circle)
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
                            .glassEffect(.regular, in: .circle)
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
    EditSignModal(sign: Sign(
        id: UUID(),
        boardId: UUID(),
        label: "Dishwasher",
        emoji: "🍽️",
        stateOffLabel: "Dirty",
        stateOnLabel: "Clean",
        active: false,
        lastChangedAt: Date(),
        lastChangedBy: "Alice",
        position: 0,
        colorIndex: 0,
        createdAt: Date()
    ), signsVM: SignsViewModel())
}
