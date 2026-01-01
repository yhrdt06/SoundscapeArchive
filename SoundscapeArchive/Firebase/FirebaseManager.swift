import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

/// Singleton manager for Firebase services
@MainActor
final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    let auth: Auth
    let firestore: Firestore
    let storage: Storage

    private init() {
        // Note: FirebaseApp.configure() is called in App init
        auth = Auth.auth()
        firestore = Firestore.firestore()
        storage = Storage.storage()

        // Configure Firestore settings
        let settings = firestore.settings
        // Enable offline persistence with 100MB cache
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: 100 * 1024 * 1024 as NSNumber)
        firestore.settings = settings
    }
}

// MARK: - Collection References
extension FirebaseManager {
    /// Users collection reference
    var usersCollection: CollectionReference {
        firestore.collection("users")
    }

    /// Soundscapes collection reference
    var soundscapesCollection: CollectionReference {
        firestore.collection("soundscapes")
    }

    /// Evaluations collection reference
    var evaluationsCollection: CollectionReference {
        firestore.collection("evaluations")
    }

    /// Storage reference for user audio files
    func userAudioStorageRef(userId: String, recordId: String) -> StorageReference {
        storage.reference()
            .child("users")
            .child(userId)
            .child("soundscapes")
            .child(recordId)
            .child("audio.wav")
    }
}
