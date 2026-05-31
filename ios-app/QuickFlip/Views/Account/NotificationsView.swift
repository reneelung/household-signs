import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var newSign = true
    @State private var signFlipped = true
    @State private var memberJoined = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    Toggle("New sign added", isOn: $newSign)
                    Toggle("Sign flipped", isOn: $signFlipped)
                    Toggle("Member joined", isOn: $memberJoined)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
