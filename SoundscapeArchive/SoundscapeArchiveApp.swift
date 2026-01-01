import SwiftUI
import SwiftData
import FirebaseCore

@main
struct SoundscapeArchiveApp: App {
    @StateObject private var authManager = AuthManager()

    init() {
        FirebaseApp.configure()
        configureSyncManager()
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

    private func configureSyncManager() {
        let firestoreClient = FirestoreClient()
        let storageClient = StorageClient()
        SyncManager.shared.configure(
            firestoreClient: firestoreClient,
            storageClient: storageClient
        )
    }
}
