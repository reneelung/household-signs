import SwiftUI

struct ProfileView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        MemberAvatarBubble(name: authVM.displayName, size: 56)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(authVM.displayName)
                                .font(.system(size: 20, weight: .bold))
                            if !authVM.accountEmail.isEmpty {
                                Text(authVM.accountEmail)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }

                Section("Account") {
                    LabeledContent("Email", value: authVM.accountEmail)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
