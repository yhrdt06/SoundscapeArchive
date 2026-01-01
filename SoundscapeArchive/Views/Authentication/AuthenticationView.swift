import SwiftUI

/// Main authentication view with sign in / sign up toggle
struct AuthenticationView: View {
    @State private var showSignUp = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)

                    Text("SoundscapeArchive")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("サウンドスケープを記録・分析")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)

                Spacer()

                // Auth form
                if showSignUp {
                    SignUpView(showSignUp: $showSignUp)
                } else {
                    SignInView(showSignUp: $showSignUp)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthManager())
}
