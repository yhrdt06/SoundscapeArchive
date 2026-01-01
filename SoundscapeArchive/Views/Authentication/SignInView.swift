import SwiftUI

/// Sign in form view
struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showPasswordReset = false

    var body: some View {
        VStack(spacing: 20) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("メールアドレス")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("example@email.com", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
            }

            // Sign in button
            Button(action: signIn) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("ログイン")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isFormValid || isLoading)

            // Forgot password
            Button("パスワードを忘れた場合") {
                showPasswordReset = true
            }
            .font(.footnote)
            .foregroundStyle(.blue)

            Divider()
                .padding(.vertical)

            // Sign up link
            HStack {
                Text("アカウントをお持ちでない場合")
                    .foregroundStyle(.secondary)

                Button("新規登録") {
                    showSignUp = true
                }
                .fontWeight(.semibold)
            }
            .font(.footnote)
        }
        .padding()
        .alert("エラー", isPresented: $showError) {
            Button("OK") {
                authManager.clearError()
            }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private func signIn() {
        isLoading = true

        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch let error as AuthError {
                errorMessage = error.localizedDescription
                showError = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

/// Password reset sheet
struct PasswordResetView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("パスワードリセット用のメールを送信します")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                TextField("メールアドレス", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                Button(action: sendReset) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("送信")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(email.contains("@") ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(!email.contains("@") || isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("パスワードリセット")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .alert("送信完了", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("パスワードリセット用のメールを送信しました")
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func sendReset() {
        isLoading = true

        Task {
            do {
                try await authManager.sendPasswordReset(email: email)
                showSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isLoading = false
        }
    }
}

#Preview {
    SignInView(showSignUp: .constant(false))
        .environmentObject(AuthManager())
}
