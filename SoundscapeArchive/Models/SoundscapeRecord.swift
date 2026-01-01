import Foundation

/// Complete soundscape record
struct SoundscapeRecord: Codable, Identifiable, Equatable {
    /// Unique identifier (format: "rec_timestamp_hex8")
    let id: String

    /// User ID
    let userId: String

    /// Recording metadata
    var metadata: SoundscapeMetadata

    /// Acoustic analysis results (populated after server processing)
    var acousticAnalysis: AcousticAnalysis?

    /// Subjective evaluation (populated after user evaluation)
    var evaluation: SubjectiveEvaluation?

    /// Path to audio file in Firebase Storage
    var audioFilePath: String?

    /// Waveform preview data for display
    var waveformPreview: [Double]?

    /// Record creation timestamp
    let createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Synchronization status
    var syncStatus: SyncStatus

    enum CodingKeys: String, CodingKey {
        case id, metadata, evaluation
        case userId = "user_id"
        case acousticAnalysis = "acoustic_analysis"
        case audioFilePath = "audio_file_path"
        case waveformPreview = "waveform_preview"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncStatus = "sync_status"
    }

    init(
        id: String = SoundscapeRecord.generateId(),
        userId: String,
        metadata: SoundscapeMetadata,
        acousticAnalysis: AcousticAnalysis? = nil,
        evaluation: SubjectiveEvaluation? = nil,
        audioFilePath: String? = nil,
        waveformPreview: [Double]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.userId = userId
        self.metadata = metadata
        self.acousticAnalysis = acousticAnalysis
        self.evaluation = evaluation
        self.audioFilePath = audioFilePath
        self.waveformPreview = waveformPreview
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus
    }

    /// Generate a unique ID (format: "rec_timestamp_hex8")
    static func generateId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomHex = String(format: "%08x", UInt32.random(in: 0...UInt32.max))
        return "rec_\(timestamp)_\(randomHex)"
    }

    /// Check if this record has been analyzed
    var hasAnalysis: Bool {
        acousticAnalysis != nil
    }

    /// Get LAeq value if available
    var laeq: Double? {
        acousticAnalysis?.laeq
    }

    /// Check if this record has evaluation
    var hasEvaluation: Bool {
        evaluation != nil
    }
}

// MARK: - Hashable
extension SoundscapeRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
