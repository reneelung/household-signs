import SwiftUI

struct AddSignModal: View {
    @Bindable var signsVM: SignsViewModel
    @Environment(\.dismiss) var dismiss

    @State private var label = ""
    @State private var selectedEmoji = "📌"
    @State private var stateOffLabel = ""
    @State private var stateOnLabel = ""

    private var isFormValid: Bool {
        !label.isEmpty && !stateOffLabel.isEmpty && !stateOnLabel.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack {
                        Text("Add Sign")
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

                    ScrollView {
                        VStack(spacing: 20) {
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
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                                    .onChange(of: label) { _, newValue in
                                        if newValue.count > 20 {
                                            label = String(newValue.prefix(20))
                                        }
                                    }
                            }

                            VStack(spacing: 12) {
                                Text("Off Label")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("e.g., Dirty", text: $stateOffLabel)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                                    .onChange(of: stateOffLabel) { _, newValue in
                                        if newValue.count > 16 {
                                            stateOffLabel = String(newValue.prefix(16))
                                        }
                                    }
                            }

                            VStack(spacing: 12) {
                                Text("On Label")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.appSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                TextField("e.g., Clean", text: $stateOnLabel)
                                    .padding(12)
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
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
                            }

                            Button(action: {
                                Task {
                                    await signsVM.addSign(
                                        label: label,
                                        emoji: selectedEmoji,
                                        stateOffLabel: stateOffLabel,
                                        stateOnLabel: stateOnLabel
                                    )
                                    dismiss()
                                }
                            }) {
                                if signsVM.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Sign")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(isFormValid && !signsVM.isLoading ? Color.appAccent : Color.appBorder)
                            .foregroundColor(isFormValid && !signsVM.isLoading ? Color.white : Color.appSecondary)
                            .cornerRadius(8)
                            .disabled(!isFormValid || signsVM.isLoading)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AddSignModal(signsVM: SignsViewModel())
}
