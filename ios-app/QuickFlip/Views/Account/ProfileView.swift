import SwiftUI

struct ProfileView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isEditingName = false
    @State private var editedName = ""

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
                    Button {
                        editedName = authVM.displayName
                        isEditingName = true
                    } label: {
                        HStack {
                            Text("Name")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(authVM.displayName)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.secondary.opacity(0.5))
                        }
                    }

                    LabeledContent("Email", value: authVM.accountEmail)
                }

                if !authVM.errorMessage.isEmpty {
                    Section {
                        Text(authVM.errorMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Edit display name", isPresented: $isEditingName) {
                TextField("Display name", text: $editedName)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                Button("Save") {
                    let newName = editedName
                    Task { await authVM.updateDisplayName(newName) }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This is how other members will see you on shared groups.")
            }
        }
    }
}
