import SwiftUI

struct SettingsView: View {
    @Bindable var authVM: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    LabeledContent("Name", value: authVM.displayName)
                    LabeledContent("Email", value: authVM.accountEmail)
                }
                Section("Appearance") {
                    Picker("Theme", selection: .constant("Automatic")) {
                        Text("Automatic").tag("Automatic")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
