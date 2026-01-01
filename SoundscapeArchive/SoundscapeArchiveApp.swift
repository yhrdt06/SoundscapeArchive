import SwiftUI
import SwiftData
import FirebaseCore

@main
struct SoundscapeArchiveApp: App {
    @StateObject private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
        .modelContainer(for: [
            LocalSoundscapeRecord.self,
            LocalEvaluation.self
        ])
    }
}
