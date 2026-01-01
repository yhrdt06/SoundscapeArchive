import Foundation
import SwiftData

/// SwiftData model for local storage of soundscape records
@Model
final class LocalSoundscapeRecord {
    /// Unique identifier (matches SoundscapeRecord.id)
    @Attribute(.unique) var id: String

    /// User ID who created this record
    var userId: String

    /// Metadata stored as JSON
    var metadataJSON: Data

    /// Analysis results stored as JSON (optional)
    var analysisJSON: Data?

    /// Local path to audio file
    var localAudioPath: String

    /// Remote path in Firebase Storage
    var remoteAudioPath: String?

    /// Waveform preview data stored as JSON
    var waveformPreviewJSON: Data?

    /// Evaluation stored as JSON (optional)
    var evaluationJSON: Data?

    /// Sync status raw value
    var syncStatusRaw: String

    /// Remote version number for conflict detection
    var remoteVersion: Int

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    init(
        id: String,
        userId: String,
        metadataJSON: Data,
        analysisJSON: Data? = nil,
        localAudioPath: String,
        remoteAudioPath: String? = nil,
        waveformPreviewJSON: Data? = nil,
        evaluationJSON: Data? = nil,
        syncStatusRaw: String = SyncStatus.pendingUpload.rawValue,
        remoteVersion: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.metadataJSON = metadataJSON
        self.analysisJSON = analysisJSON
        self.localAudioPath = localAudioPath
        self.remoteAudioPath = remoteAudioPath
        self.waveformPreviewJSON = waveformPreviewJSON
        self.evaluationJSON = evaluationJSON
        self.syncStatusRaw = syncStatusRaw
        self.remoteVersion = remoteVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
extension LocalSoundscapeRecord {
    /// Decoded metadata
    var metadata: SoundscapeMetadata? {
        try? JSONDecoder().decode(SoundscapeMetadata.self, from: metadataJSON)
    }

    /// Decoded analysis
    var analysis: AcousticAnalysis? {
        guard let data = analysisJSON else { return nil }
        return try? JSONDecoder().decode(AcousticAnalysis.self, from: data)
    }

    /// Decoded waveform preview
    var waveformPreview: [Double]? {
        guard let data = waveformPreviewJSON else { return nil }
        return try? JSONDecoder().decode([Double].self, from: data)
    }

    /// Decoded evaluation
    var evaluation: SubjectiveEvaluation? {
        guard let data = evaluationJSON else { return nil }
        return try? JSONDecoder().decode(SubjectiveEvaluation.self, from: data)
    }

    /// Sync status enum
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingUpload }
        set { syncStatusRaw = newValue.rawValue }
    }
}

// MARK: - Conversion Methods
extension LocalSoundscapeRecord {
    /// Create from SoundscapeRecord
    static func from(_ record: SoundscapeRecord, localAudioPath: String) throws -> LocalSoundscapeRecord {
        let encoder = JSONEncoder()
        let metadataJSON = try encoder.encode(record.metadata)
        let analysisJSON = record.acousticAnalysis != nil ? try encoder.encode(record.acousticAnalysis) : nil
        let waveformJSON = record.waveformPreview != nil ? try encoder.encode(record.waveformPreview) : nil
        let evaluationJSON = record.evaluation != nil ? try encoder.encode(record.evaluation) : nil

        return LocalSoundscapeRecord(
            id: record.id,
            userId: record.userId,
            metadataJSON: metadataJSON,
            analysisJSON: analysisJSON,
            localAudioPath: localAudioPath,
            remoteAudioPath: record.audioFilePath,
            waveformPreviewJSON: waveformJSON,
            evaluationJSON: evaluationJSON,
            syncStatusRaw: record.syncStatus.rawValue,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
    }

    /// Convert to SoundscapeRecord
    func toSoundscapeRecord() -> SoundscapeRecord? {
        guard let metadata = metadata else { return nil }

        return SoundscapeRecord(
            id: id,
            userId: userId,
            metadata: metadata,
            acousticAnalysis: analysis,
            evaluation: evaluation,
            audioFilePath: remoteAudioPath,
            waveformPreview: waveformPreview,
            createdAt: createdAt,
            updatedAt: updatedAt,
            syncStatus: syncStatus
        )
    }
}
