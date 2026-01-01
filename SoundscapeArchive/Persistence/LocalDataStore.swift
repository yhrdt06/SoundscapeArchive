import Foundation
import SwiftData

/// Local data access layer using SwiftData
@MainActor
final class LocalDataStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Soundscape Records

    /// Fetch all records for a user
    func fetchAllRecords(userId: String) throws -> [SoundscapeRecord] {
        let predicate = #Predicate<LocalSoundscapeRecord> { record in
            record.userId == userId
        }
        let descriptor = FetchDescriptor<LocalSoundscapeRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        let localRecords = try modelContext.fetch(descriptor)
        return localRecords.compactMap { $0.toSoundscapeRecord() }
    }

    /// Fetch a specific record by ID
    func fetchRecord(id: String) throws -> SoundscapeRecord? {
        let predicate = #Predicate<LocalSoundscapeRecord> { record in
            record.id == id
        }
        let descriptor = FetchDescriptor<LocalSoundscapeRecord>(predicate: predicate)

        return try modelContext.fetch(descriptor).first?.toSoundscapeRecord()
    }

    /// Fetch records by sync status
    func fetchRecordsByStatus(_ status: SyncStatus, userId: String) throws -> [SoundscapeRecord] {
        let statusRaw = status.rawValue
        let predicate = #Predicate<LocalSoundscapeRecord> { record in
            record.userId == userId && record.syncStatusRaw == statusRaw
        }
        let descriptor = FetchDescriptor<LocalSoundscapeRecord>(predicate: predicate)

        return try modelContext.fetch(descriptor).compactMap { $0.toSoundscapeRecord() }
    }

    /// Save a new record
    func saveRecord(_ record: SoundscapeRecord, localAudioPath: String) throws {
        let localRecord = try LocalSoundscapeRecord.from(record, localAudioPath: localAudioPath)
        modelContext.insert(localRecord)
        try modelContext.save()
    }

    /// Update an existing record
    func updateRecord(_ record: SoundscapeRecord) throws {
        let predicate = #Predicate<LocalSoundscapeRecord> { r in
            r.id == record.id
        }
        let descriptor = FetchDescriptor<LocalSoundscapeRecord>(predicate: predicate)

        guard let localRecord = try modelContext.fetch(descriptor).first else {
            throw LocalDataStoreError.recordNotFound
        }

        let encoder = JSONEncoder()
        localRecord.metadataJSON = try encoder.encode(record.metadata)
        localRecord.analysisJSON = record.acousticAnalysis != nil ? try encoder.encode(record.acousticAnalysis) : nil
        localRecord.waveformPreviewJSON = record.waveformPreview != nil ? try encoder.encode(record.waveformPreview) : nil
        localRecord.evaluationJSON = record.evaluation != nil ? try encoder.encode(record.evaluation) : nil
        localRecord.remoteAudioPath = record.audioFilePath
        localRecord.syncStatusRaw = record.syncStatus.rawValue
        localRecord.updatedAt = Date()

        try modelContext.save()
    }

    /// Update sync status
    func updateSyncStatus(recordId: String, status: SyncStatus) throws {
        let predicate = #Predicate<LocalSoundscapeRecord> { record in
            record.id == recordId
        }
        let descriptor = FetchDescriptor<LocalSoundscapeRecord>(predicate: predicate)

        guard let localRecord = try modelContext.fetch(descriptor).first else {
            throw LocalDataStoreError.recordNotFound
        }

        localRecord.syncStatusRaw = status.rawValue
        localRecord.updatedAt = Date()
        try modelContext.save()
    }

    /// Delete a record
    func deleteRecord(id: String) throws {
        let predicate = #Predicate<LocalSoundscapeRecord> { record in
            record.id == id
        }
        let descriptor = FetchDescriptor<LocalSoundscapeRecord>(predicate: predicate)

        guard let localRecord = try modelContext.fetch(descriptor).first else {
            throw LocalDataStoreError.recordNotFound
        }

        modelContext.delete(localRecord)
        try modelContext.save()
    }

    /// Get local audio path for a record
    func getAudioPath(recordId: String) throws -> String {
        let predicate = #Predicate<LocalSoundscapeRecord> { record in
            record.id == recordId
        }
        let descriptor = FetchDescriptor<LocalSoundscapeRecord>(predicate: predicate)

        guard let localRecord = try modelContext.fetch(descriptor).first else {
            throw LocalDataStoreError.recordNotFound
        }

        return localRecord.localAudioPath
    }

    // MARK: - Evaluations

    /// Fetch all evaluations for a record
    func fetchEvaluations(recordId: String) throws -> [SubjectiveEvaluation] {
        let predicate = #Predicate<LocalEvaluation> { eval in
            eval.recordId == recordId
        }
        let descriptor = FetchDescriptor<LocalEvaluation>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        return try modelContext.fetch(descriptor).compactMap { $0.toSubjectiveEvaluation() }
    }

    /// Save a new evaluation
    func saveEvaluation(_ evaluation: SubjectiveEvaluation, userId: String) throws {
        let localEvaluation = try LocalEvaluation.from(evaluation, userId: userId)
        modelContext.insert(localEvaluation)
        try modelContext.save()
    }

    /// Delete an evaluation
    func deleteEvaluation(id: String) throws {
        let predicate = #Predicate<LocalEvaluation> { eval in
            eval.id == id
        }
        let descriptor = FetchDescriptor<LocalEvaluation>(predicate: predicate)

        guard let localEvaluation = try modelContext.fetch(descriptor).first else {
            throw LocalDataStoreError.evaluationNotFound
        }

        modelContext.delete(localEvaluation)
        try modelContext.save()
    }
}

// MARK: - Errors
enum LocalDataStoreError: Error, LocalizedError {
    case recordNotFound
    case evaluationNotFound
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .recordNotFound:
            return "録音データが見つかりません"
        case .evaluationNotFound:
            return "評価データが見つかりません"
        case .encodingFailed:
            return "データのエンコードに失敗しました"
        case .decodingFailed:
            return "データのデコードに失敗しました"
        }
    }
}
