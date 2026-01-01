import Foundation
import FirebaseStorage

/// Firebase Storage access layer
final class StorageClient {
    private let storage: Storage

    init(storage: Storage = FirebaseManager.shared.storage) {
        self.storage = storage
    }

    // MARK: - Audio Files

    /// Upload an audio file to Firebase Storage
    /// - Parameters:
    ///   - localURL: Local file URL
    ///   - userId: User ID
    ///   - recordId: Record ID
    /// - Returns: Download URL
    func uploadAudioFile(from localURL: URL, userId: String, recordId: String) async throws -> URL {
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("soundscapes")
            .child(recordId)
            .child("audio.wav")

        // Set metadata
        let metadata = StorageMetadata()
        metadata.contentType = "audio/wav"

        // Upload file
        _ = try await storageRef.putFileAsync(from: localURL, metadata: metadata)

        // Get download URL
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }

    /// Upload audio data to Firebase Storage
    func uploadAudioData(_ data: Data, userId: String, recordId: String) async throws -> URL {
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("soundscapes")
            .child(recordId)
            .child("audio.wav")

        let metadata = StorageMetadata()
        metadata.contentType = "audio/wav"

        _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }

    /// Download audio file to local URL
    /// - Parameters:
    ///   - userId: User ID
    ///   - recordId: Record ID
    ///   - localURL: Destination local URL
    func downloadAudioFile(userId: String, recordId: String, to localURL: URL) async throws {
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("soundscapes")
            .child(recordId)
            .child("audio.wav")

        _ = try await storageRef.writeAsync(toFile: localURL)
    }

    /// Get download URL for an audio file
    func getAudioDownloadURL(userId: String, recordId: String) async throws -> URL {
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("soundscapes")
            .child(recordId)
            .child("audio.wav")

        return try await storageRef.downloadURL()
    }

    /// Delete an audio file
    func deleteAudioFile(userId: String, recordId: String) async throws {
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("soundscapes")
            .child(recordId)
            .child("audio.wav")

        try await storageRef.delete()
    }

    /// Check if audio file exists
    func audioFileExists(userId: String, recordId: String) async -> Bool {
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("soundscapes")
            .child(recordId)
            .child("audio.wav")

        do {
            _ = try await storageRef.getMetadata()
            return true
        } catch {
            return false
        }
    }
}
