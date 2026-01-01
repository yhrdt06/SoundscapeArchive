import Foundation
import FirebaseAuth
import Combine

/// Authentication state manager
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = true
    @Published private(set) var error: AuthError?

    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        setupAuthStateListener()
    }

    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }

    // MARK: - Auth State Listener

    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                self?.isLoading = false
            }
        }
    }

    // MARK: - Current User Info

    /// Current user's ID
    var userId: String? {
        currentUser?.uid
    }

    /// Current user's email
    var userEmail: String? {
        currentUser?.email
    }

    /// Current user's display name
    var displayName: String? {
        currentUser?.displayName
    }

    // MARK: - Sign In

    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        error = nil

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user
            isAuthenticated = true
        } catch let authError as NSError {
            self.error = AuthError.from(authError)
            throw self.error!
        }

        isLoading = false
    }

    // MARK: - Sign Up

    /// Create a new account with email and password
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        isLoading = true
        error = nil

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Update display name if provided
            if let displayName = displayName {
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
            }

            currentUser = result.user
            isAuthenticated = true
        } catch let authError as NSError {
            self.error = AuthError.from(authError)
            throw self.error!
        }

        isLoading = false
    }

    // MARK: - Sign Out

    /// Sign out the current user
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = .signOutFailed
            throw AuthError.signOutFailed
        }
    }

    // MARK: - Password Reset

    /// Send password reset email
    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let authError as NSError {
            self.error = AuthError.from(authError)
            throw self.error!
        }
    }

    // MARK: - Update Profile

    /// Update display name
    func updateDisplayName(_ name: String) async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }

        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = name
        try await changeRequest.commitChanges()
    }

    // MARK: - Delete Account

    /// Delete the current user's account
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthError.notAuthenticated
        }

        try await user.delete()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Clear Error

    func clearError() {
        error = nil
    }
}

// MARK: - Auth Errors
enum AuthError: Error, LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case notAuthenticated
    case signOutFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "メールアドレスの形式が正しくありません"
        case .wrongPassword:
            return "パスワードが間違っています"
        case .userNotFound:
            return "ユーザーが見つかりません"
        case .emailAlreadyInUse:
            return "このメールアドレスは既に使用されています"
        case .weakPassword:
            return "パスワードは6文字以上にしてください"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .notAuthenticated:
            return "ログインしていません"
        case .signOutFailed:
            return "ログアウトに失敗しました"
        case .unknown(let message):
            return message
        }
    }

    static func from(_ error: NSError) -> AuthError {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return .unknown(error.localizedDescription)
        }

        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
