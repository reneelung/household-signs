import Supabase
import Foundation
import Observation

enum AuthStep {
    case loading
    case auth
    case nickname
    case done
}

@Observable
class AuthViewModel {
    var authStep: AuthStep = .loading
    var isSignUp = false
    var email = ""
    var password = ""
    var nickname = ""
    var errorMessage = ""
    var isLoading = false
    var user: User?
    private var authSubscription: Task<Void, Never>?

    init() {
        setupAuthListener()
    }

    private func setupAuthListener() {
        authSubscription = Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    self.user = session?.user
                    self.updateAuthStep()
                }
            }
        }
    }

    private func updateAuthStep() {
        guard let user = user else {
            authStep = .auth
            return
        }
        let displayName = user.userMetadata["display_name"]?.stringValue
        authStep = (displayName?.isEmpty ?? true) ? .nickname : .done
    }

    @MainActor
    func signUp() async {
        errorMessage = ""
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await supabase.auth.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func signIn() async {
        errorMessage = ""
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await supabase.auth.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func setNickname() async {
        errorMessage = ""
        isLoading = true
        defer { isLoading = false }
        do {
            try await supabase.auth.update(user: UserAttributes(data: [
                "display_name": .string(nickname)
            ]))
            authStep = .done
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            email = ""
            password = ""
            nickname = ""
            errorMessage = ""
            authStep = .auth
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    deinit {
        authSubscription?.cancel()
    }
}
