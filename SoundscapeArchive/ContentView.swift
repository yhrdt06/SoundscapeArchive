import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView("読み込み中...")
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
