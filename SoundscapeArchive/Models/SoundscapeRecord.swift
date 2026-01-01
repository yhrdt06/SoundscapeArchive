import Foundation

/// Complete soundscape record
struct SoundscapeRecord: Codable, Identifiable, Equatable {
    /// Unique identifier (format: "rec_timestamp_hex8")
    let id: String

    /// Recording metadata
    var metadata: SoundscapeMetadata

    /// Acoustic analysis results (populated after server processing)
    var analysis: AcousticAnalysis?

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
        case id, metadata, analysis
        case audioFilePath = "audio_file_path"
        case waveformPreview = "waveform_preview"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncStatus = "sync_status"
    }

    init(
        id: String = SoundscapeRecord.generateId(),
        metadata: SoundscapeMetadata,
        analysis: AcousticAnalysis? = nil,
        audioFilePath: String? = nil,
        waveformPreview: [Double]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.metadata = metadata
        self.analysis = analysis
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
        analysis != nil
    }

    /// Get LAeq value if available
    var laeq: Double? {
        analysis?.laeq
    }
}

// MARK: - Hashable
extension SoundscapeRecord: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
