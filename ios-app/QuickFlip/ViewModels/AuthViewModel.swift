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

    var displayName: String {
        user?.userMetadata["display_name"]?.stringValue ?? "Account"
    }

    var accountEmail: String {
        user?.email ?? ""
    }

    var initial: String {
        String(displayName.prefix(1)).uppercased()
    }
}

@Observable
final class PendingJoin {
    static let shared = PendingJoin()

    private let key = "pendingInviteCode"

    var code: String? {
        didSet {
            if let code {
                UserDefaults.standard.set(code, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    private init() {
        self.code = UserDefaults.standard.string(forKey: key)
    }

    func clear() {
        code = nil
    }
}

enum JoinGroupCoordinator {
    static let allowedHosts: Set<String> = [
        "quickflip-app.reneelung.workers.dev"
    ]

    @discardableResult
    static func handle(_ url: URL) -> Bool {
        guard let host = url.host, allowedHosts.contains(host) else { return false }
        let parts = url.pathComponents
        guard parts.count >= 3, parts[1] == "join" else { return false }
        let code = parts[2]
        guard !code.isEmpty else { return false }
        PendingJoin.shared.code = code
        return true
    }
}
