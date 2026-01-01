import Foundation
import SwiftData

/// SwiftData model for local storage of subjective evaluations
@Model
final class LocalEvaluation {
    /// Unique identifier
    @Attribute(.unique) var id: String

    /// Associated soundscape record ID
    var recordId: String

    /// User ID who created this evaluation
    var userId: String

    /// Evaluation data stored as JSON
    var evaluationJSON: Data

    /// Sync status raw value
    var syncStatusRaw: String

    /// Remote version for conflict detection
    var remoteVersion: Int

    /// Creation timestamp
    var createdAt: Date

    /// Last update timestamp
    var updatedAt: Date

    init(
        id: String,
        recordId: String,
        userId: String,
        evaluationJSON: Data,
        syncStatusRaw: String = SyncStatus.pendingUpload.rawValue,
        remoteVersion: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.recordId = recordId
        self.userId = userId
        self.evaluationJSON = evaluationJSON
        self.syncStatusRaw = syncStatusRaw
        self.remoteVersion = remoteVersion
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Computed Properties
extension LocalEvaluation {
    /// Decoded evaluation
    var evaluation: SubjectiveEvaluation? {
        try? JSONDecoder().decode(SubjectiveEvaluation.self, from: evaluationJSON)
    }

    /// Sync status enum
    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pendingUpload }
        set { syncStatusRaw = newValue.rawValue }
    }
}

// MARK: - Conversion Methods
extension LocalEvaluation {
    /// Create from SubjectiveEvaluation
    static func from(_ evaluation: SubjectiveEvaluation, userId: String) throws -> LocalEvaluation {
        let encoder = JSONEncoder()
        let evaluationJSON = try encoder.encode(evaluation)

        return LocalEvaluation(
            id: evaluation.id,
            recordId: evaluation.recordId,
            userId: userId,
            evaluationJSON: evaluationJSON,
            syncStatusRaw: evaluation.syncStatus.rawValue,
            createdAt: evaluation.createdAt,
            updatedAt: evaluation.updatedAt
        )
    }

    /// Convert to SubjectiveEvaluation
    func toSubjectiveEvaluation() -> SubjectiveEvaluation? {
        return evaluation
    }
}
