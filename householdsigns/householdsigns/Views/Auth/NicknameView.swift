import SwiftUI

struct NicknameView: View {
    @Bindable var authVM: AuthViewModel

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 24) {
                    Text("Choose a Nickname")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.appText)

                    Text("This is how others will see you when you flip signs.")
                        .font(.system(size: 15))
                        .foregroundColor(.appSecondary)
                        .multilineTextAlignment(.center)

                    TextField("Enter your nickname", text: $authVM.nickname)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))

                    if !authVM.errorMessage.isEmpty {
                        Text(authVM.errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                    }

                    Button(action: {
                        Task {
                            await authVM.setNickname()
                        }
                    }) {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Continue").font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.appAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(authVM.isLoading || authVM.nickname.isEmpty)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 4)
                .padding(20)

                Spacer()
            }
        }
    }
}

#Preview {
    NicknameView(authVM: AuthViewModel())
}
