import Foundation
import SwiftData

/// Manages synchronization between local SwiftData and Firebase
@MainActor
@Observable
final class SyncManager {
    // MARK: - Singleton

    static let shared = SyncManager()

    // MARK: - State

    private(set) var isSyncing = false
    private(set) var lastSyncDate: Date?
    private(set) var pendingCount = 0
    private(set) var error: Error?

    // MARK: - Dependencies

    private var firestoreClient: FirestoreClient?
    private var storageClient: StorageClient?

    // MARK: - Init

    private init() {}

    func configure(firestoreClient: FirestoreClient, storageClient: StorageClient) {
        self.firestoreClient = firestoreClient
        self.storageClient = storageClient
    }

    // MARK: - Sync Operations

    /// Perform full sync (upload pending, download new)
    func sync(context: ModelContext) async throws {
        guard let userId = AuthManager.shared.userId else {
            throw SyncError.notAuthenticated
        }

        guard !isSyncing else { return }

        isSyncing = true
        error = nil

        do {
            // Step 1: Upload pending records
            try await uploadPendingRecords(context: context, userId: userId)

            // Step 2: Download remote changes
            try await downloadRemoteChanges(context: context, userId: userId)

            // Step 3: Resolve conflicts if any
            try await resolveConflicts(context: context, userId: userId)

            lastSyncDate = Date()
        } catch {
            self.error = error
            throw error
        }

        isSyncing = false
    }

    /// Upload only pending records
    func uploadPending(context: ModelContext) async throws {
        guard let userId = AuthManager.shared.userId else {
            throw SyncError.notAuthenticated
        }

        try await uploadPendingRecords(context: context, userId: userId)
    }

    /// Get count of pending uploads
    func updatePendingCount(context: ModelContext) {
        guard let userId = AuthManager.shared.userId else {
            pendingCount = 0
            return
        }

        do {
            let dataStore = LocalDataStore(modelContext: context)
            let pending = try dataStore.fetchRecordsByStatus(.pendingUpload, userId: userId)
            pendingCount = pending.count
        } catch {
            pendingCount = 0
        }
    }

    // MARK: - Private Methods

    private func uploadPendingRecords(context: ModelContext, userId: String) async throws {
        guard let firestoreClient = firestoreClient,
              let storageClient = storageClient else {
            throw SyncError.notConfigured
        }

        let dataStore = LocalDataStore(modelContext: context)
        let pendingRecords = try dataStore.fetchRecordsByStatus(.pendingUpload, userId: userId)

        for record in pendingRecords {
            do {
                // Upload audio file if not already uploaded
                var updatedRecord = record
                if updatedRecord.audioFilePath == nil {
                    let localPath = try dataStore.getAudioPath(recordId: record.id)
                    let localURL = URL(fileURLWithPath: localPath)

                    let remotePath = try await storageClient.uploadAudio(
                        localURL: localURL,
                        recordId: record.id,
                        userId: userId
                    )
                    updatedRecord.audioFilePath = remotePath
                }

                // Upload record to Firestore
                try await firestoreClient.saveRecord(updatedRecord, userId: userId)

                // Update local status
                updatedRecord.syncStatus = .synced
                updatedRecord.updatedAt = Date()
                try dataStore.updateRecord(updatedRecord)
            } catch {
                print("Failed to upload record \(record.id): \(error)")
                // Continue with other records
            }
        }

        updatePendingCount(context: context)
    }

    private func downloadRemoteChanges(context: ModelContext, userId: String) async throws {
        guard let firestoreClient = firestoreClient else {
            throw SyncError.notConfigured
        }

        let dataStore = LocalDataStore(modelContext: context)

        // Get last sync timestamp
        let since = lastSyncDate ?? Date.distantPast

        // Fetch remote records updated since last sync
        let remoteRecords = try await firestoreClient.fetchRecords(
            userId: userId,
            since: since
        )

        for remoteRecord in remoteRecords {
            // Check if we have this record locally
            if let localRecord = try dataStore.fetchRecord(id: remoteRecord.id) {
                // Check for conflicts
                if localRecord.syncStatus == .pendingUpload {
                    // Conflict: local changes not yet uploaded
                    try dataStore.updateSyncStatus(recordId: remoteRecord.id, status: .conflict)
                } else {
                    // No conflict: update local with remote
                    try dataStore.updateRecord(remoteRecord)
                }
            } else {
                // New record from remote - need to download audio
                var newRecord = remoteRecord
                newRecord.syncStatus = .pendingDownload

                // Create placeholder local record
                // Audio will be downloaded on demand
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let localAudioPath = documentsPath.appendingPathComponent("Audio/\(remoteRecord.id).wav").path

                try dataStore.saveRecord(newRecord, localAudioPath: localAudioPath)
            }
        }
    }

    private func resolveConflicts(context: ModelContext, userId: String) async throws {
        let dataStore = LocalDataStore(modelContext: context)
        let conflictRecords = try dataStore.fetchRecordsByStatus(.conflict, userId: userId)

        for record in conflictRecords {
            // Default resolution: Keep remote version
            // In a real app, you might want to present a UI for conflict resolution
            try dataStore.updateSyncStatus(recordId: record.id, status: .synced)
        }
    }

    /// Download audio file for a record
    func downloadAudio(recordId: String, context: ModelContext) async throws {
        guard let storageClient = storageClient,
              let userId = AuthManager.shared.userId else {
            throw SyncError.notConfigured
        }

        let dataStore = LocalDataStore(modelContext: context)

        guard let record = try dataStore.fetchRecord(id: recordId),
              let remotePath = record.audioFilePath else {
            throw SyncError.recordNotFound
        }

        // Create local directory if needed
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioDir = documentsPath.appendingPathComponent("Audio")
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)

        let localURL = audioDir.appendingPathComponent("\(recordId).wav")

        // Download file
        try await storageClient.downloadAudio(remotePath: remotePath, to: localURL)

        // Update sync status
        try dataStore.updateSyncStatus(recordId: recordId, status: .synced)
    }
}

// MARK: - Errors

enum SyncError: Error, LocalizedError {
    case notAuthenticated
    case notConfigured
    case recordNotFound
    case uploadFailed(String)
    case downloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "ログインしていません"
        case .notConfigured:
            return "同期機能が設定されていません"
        case .recordNotFound:
            return "録音データが見つかりません"
        case .uploadFailed(let message):
            return "アップロードに失敗しました: \(message)"
        case .downloadFailed(let message):
            return "ダウンロードに失敗しました: \(message)"
        }
    }
}
