import SwiftUI

struct AuthView: View {
    @Bindable var authVM: AuthViewModel
    @State private var isPasswordVisible = false

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack {
                Spacer()

                VStack(spacing: 24) {
                    Text(authVM.isSignUp ? "Create Account" : "Sign In")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.black)

                    VStack(spacing: 12) {
                        TextField("Email", text: $authVM.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .foregroundColor(.black)
                            .tint(.black)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))

                        HStack(spacing: 8) {
                            Group {
                                if isPasswordVisible {
                                    TextField("Password", text: $authVM.password)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                } else {
                                    SecureField("Password", text: $authVM.password)
                                        .textContentType(.password)
                                }
                            }
                            .foregroundColor(.black)
                            .tint(.black)

                            Button {
                                isPasswordVisible.toggle()
                            } label: {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(Color.black.opacity(0.55))
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                        }
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
                    }

                    if !authVM.errorMessage.isEmpty {
                        Text(authVM.errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                    }

                    Button(action: {
                        Task {
                            if authVM.isSignUp {
                                await authVM.signUp()
                            } else {
                                await authVM.signIn()
                            }
                        }
                    }) {
                        if authVM.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(authVM.isSignUp ? "Sign Up" : "Sign In")
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.appAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(authVM.isLoading || authVM.email.isEmpty || authVM.password.isEmpty)

                    HStack {
                        Text(authVM.isSignUp ? "Already have an account?" : "Don't have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(Color.black.opacity(0.55))

                        Button(action: {
                            authVM.email = ""
                            authVM.password = ""
                            authVM.errorMessage = ""
                            authVM.isSignUp.toggle()
                        }) {
                            Text(authVM.isSignUp ? "Sign In" : "Sign Up")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.appAccent)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
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
    AuthView(authVM: AuthViewModel())
}
