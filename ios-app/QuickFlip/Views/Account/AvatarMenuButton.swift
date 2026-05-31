import SwiftUI

struct AvatarMenuButton: View {
    @Bindable var authVM: AuthViewModel
    @Binding var showSettings: Bool
    @Binding var showNotifications: Bool
    @Binding var showProfile: Bool
    @Binding var confirmingSignOut: Bool

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Menu {
            Button {
                showProfile = true
            } label: {
                HStack {
                    Text(authVM.displayName)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
                Button {
                    showNotifications = true
                } label: {
                    Label("Notifications", systemImage: "bell")
                }
            }

            Section {
                Button(role: .destructive) {
                    confirmingSignOut = true
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            avatarPill
        }
        .menuOrder(.fixed)
        .accessibilityLabel("Account")
    }

    private var avatarPill: some View {
        Text(authVM.initial)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(isDark ? Color.white : Color(hex: "0F1115"))
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(isDark ? Color.white.opacity(0.16) : Color.black.opacity(0.08))
            )
            .overlay(
                Circle()
                    .strokeBorder(isDark ? Color.white.opacity(0.20) : Color.black.opacity(0.10),
                                  lineWidth: 0.5)
            )
            .contentShape(Circle())
    }
}
