import Foundation

/// Complete subjective evaluation record
/// Based on ISO/TS 12913-2 Method A
struct SubjectiveEvaluation: Codable, Identifiable, Equatable {
    /// Unique identifier
    let id: String

    /// Associated soundscape record ID
    let recordId: String

    /// PAQ 8-item scores
    var paqScores: PAQScores

    /// Appropriateness rating (0-10)
    /// この場所にとってのふさわしさ
    var appropriateness: Double

    /// Sound source perception
    var soundSources: SoundSourcePerception

    /// Free text comments (印象的だった音・出来事)
    var freeText: String?

    /// Calculated ISO metrics
    var isoMetrics: ISOMetrics

    /// Calculated source metrics
    var sourceMetrics: SourceMetrics

    /// Anonymous evaluator identifier (optional)
    var evaluatorId: String?

    /// Evaluation context
    var evaluationContext: String?

    /// Creation timestamp
    let createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    /// Synchronization status
    var syncStatus: SyncStatus

    enum CodingKeys: String, CodingKey {
        case id
        case recordId = "record_id"
        case paqScores = "paq_scores"
        case appropriateness
        case soundSources = "sound_sources"
        case freeText = "free_text"
        case isoMetrics = "iso_metrics"
        case sourceMetrics = "source_metrics"
        case evaluatorId = "evaluator_id"
        case evaluationContext = "evaluation_context"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case syncStatus = "sync_status"
    }

    init(
        id: String = UUID().uuidString,
        recordId: String,
        paqScores: PAQScores,
        appropriateness: Double,
        soundSources: SoundSourcePerception,
        freeText: String? = nil,
        evaluatorId: String? = nil,
        evaluationContext: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.recordId = recordId
        self.paqScores = paqScores
        self.appropriateness = appropriateness
        self.soundSources = soundSources
        self.freeText = freeText
        self.evaluatorId = evaluatorId
        self.evaluationContext = evaluationContext
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncStatus = syncStatus

        // Calculate ISO metrics from PAQ scores
        self.isoMetrics = ISOMetricsCalculator.calculate(from: paqScores)

        // Calculate source metrics
        self.sourceMetrics = SourceMetricsCalculator.calculate(from: soundSources)
    }

    /// Recalculate metrics when PAQ scores or sound sources change
    mutating func recalculateMetrics() {
        self.isoMetrics = ISOMetricsCalculator.calculate(from: paqScores)
        self.sourceMetrics = SourceMetricsCalculator.calculate(from: soundSources)
        self.updatedAt = Date()
    }
}

// MARK: - Hashable
extension SubjectiveEvaluation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
