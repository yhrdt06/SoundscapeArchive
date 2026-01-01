import SwiftUI

/// Sign up form view
struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @Binding var showSignUp: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            // Display name field
            VStack(alignment: .leading, spacing: 8) {
                Text("表示名")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("表示名（任意）", text: $displayName)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.name)
            }

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
                Text("パスワード（6文字以上）")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("パスワード", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
            }

            // Confirm password field
            VStack(alignment: .leading, spacing: 8) {
                Text("パスワード確認")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                SecureField("パスワード確認", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)

                if !confirmPassword.isEmpty && password != confirmPassword {
                    Text("パスワードが一致しません")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            // Sign up button
            Button(action: signUp) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("アカウント作成")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isFormValid ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(!isFormValid || isLoading)

            Divider()
                .padding(.vertical)

            // Sign in link
            HStack {
                Text("既にアカウントをお持ちの場合")
                    .foregroundStyle(.secondary)

                Button("ログイン") {
                    showSignUp = false
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
    }

    private var isFormValid: Bool {
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword
    }

    private func signUp() {
        isLoading = true

        Task {
            do {
                try await authManager.signUp(
                    email: email,
                    password: password,
                    displayName: displayName.isEmpty ? nil : displayName
                )
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

#Preview {
    SignUpView(showSignUp: .constant(true))
        .environmentObject(AuthManager())
}
