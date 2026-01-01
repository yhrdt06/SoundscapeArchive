import Foundation

/// Complete subjective evaluation record
/// Based on ISO/TS 12913-2 Method A
struct SubjectiveEvaluation: Codable, Identifiable, Equatable {
    /// Unique identifier (format: "eval_timestamp_hex8")
    let id: String

    /// Associated soundscape record ID
    let recordId: String

    /// Evaluation timestamp
    let evaluatedAt: Date

    /// PAQ 8-item scores
    var paqScores: PAQScores

    /// Calculated ISO metrics
    var isoMetrics: ISOMetrics

    /// Sound source perception
    var soundSources: SoundSourcePerception

    /// Calculated source metrics
    var sourceMetrics: SourceMetrics

    /// Overall loudness rating (1-10)
    var overallLoudness: Int

    /// Overall quality rating (1-5)
    var overallQuality: Int

    /// Appropriateness rating (0-10) - optional
    var appropriateness: Double?

    /// Free text comments (印象的だった音・出来事)
    var freeText: String?

    /// Anonymous evaluator identifier (optional)
    var evaluatorId: String?

    /// Evaluation context
    var evaluationContext: String?

    /// Synchronization status
    var syncStatus: SyncStatus

    enum CodingKeys: String, CodingKey {
        case id
        case recordId = "record_id"
        case evaluatedAt = "evaluated_at"
        case paqScores = "paq_scores"
        case isoMetrics = "iso_metrics"
        case soundSources = "sound_sources"
        case sourceMetrics = "source_metrics"
        case overallLoudness = "overall_loudness"
        case overallQuality = "overall_quality"
        case appropriateness
        case freeText = "free_text"
        case evaluatorId = "evaluator_id"
        case evaluationContext = "evaluation_context"
        case syncStatus = "sync_status"
    }

    /// Generate a unique ID (format: "eval_timestamp_hex8")
    static func generateId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let randomHex = String(format: "%08x", UInt32.random(in: 0...UInt32.max))
        return "eval_\(timestamp)_\(randomHex)"
    }

    init(
        id: String = SubjectiveEvaluation.generateId(),
        recordId: String,
        evaluatedAt: Date = Date(),
        paqScores: PAQScores,
        isoMetrics: ISOMetrics? = nil,
        soundSources: SoundSourcePerception,
        sourceMetrics: SourceMetrics? = nil,
        overallLoudness: Int = 5,
        overallQuality: Int = 3,
        appropriateness: Double? = nil,
        freeText: String? = nil,
        evaluatorId: String? = nil,
        evaluationContext: String? = nil,
        syncStatus: SyncStatus = .pendingUpload
    ) {
        self.id = id
        self.recordId = recordId
        self.evaluatedAt = evaluatedAt
        self.paqScores = paqScores
        self.soundSources = soundSources
        self.overallLoudness = overallLoudness
        self.overallQuality = overallQuality
        self.appropriateness = appropriateness
        self.freeText = freeText
        self.evaluatorId = evaluatorId
        self.evaluationContext = evaluationContext
        self.syncStatus = syncStatus

        // Calculate ISO metrics from PAQ scores if not provided
        self.isoMetrics = isoMetrics ?? ISOMetricsCalculator.calculate(from: paqScores)

        // Calculate source metrics if not provided
        self.sourceMetrics = sourceMetrics ?? SourceMetricsCalculator.calculate(from: soundSources)
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
