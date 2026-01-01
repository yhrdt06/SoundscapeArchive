import SwiftUI
import SwiftData

#if !NO_FIREBASE
import FirebaseCore
#endif

@main
struct SoundscapeArchiveApp: App {
    #if !NO_FIREBASE
    @StateObject private var authManager = AuthManager()
    #endif

    init() {
        #if !NO_FIREBASE
        FirebaseApp.configure()
        configureSyncManager()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if NO_FIREBASE
            MainTabView()
            #else
            ContentView()
                .environmentObject(authManager)
            #endif
        }
        .modelContainer(for: [
            LocalSoundscapeRecord.self,
            LocalEvaluation.self
        ])
    }

    #if !NO_FIREBASE
    private func configureSyncManager() {
        let firestoreClient = FirestoreClient()
        let storageClient = StorageClient()
        SyncManager.shared.configure(
            firestoreClient: firestoreClient,
            storageClient: storageClient
        )
    }
    #endif
}
