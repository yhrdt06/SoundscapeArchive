import Foundation
import FirebaseFirestore

/// Firestore data access layer
final class FirestoreClient {
    private let db: Firestore

    init(firestore: Firestore = FirebaseManager.shared.firestore) {
        self.db = firestore
    }

    // MARK: - Soundscape Records

    /// Save a soundscape record to Firestore
    func saveRecord(_ record: SoundscapeRecord, userId: String) async throws {
        let docRef = db.collection("soundscapes").document(record.id)

        var data = try Firestore.Encoder().encode(record)
        data["userId"] = userId

        try await docRef.setData(data)
    }

    /// Fetch a specific record by ID
    func fetchRecord(id: String) async throws -> SoundscapeRecord? {
        let docRef = db.collection("soundscapes").document(id)
        let snapshot = try await docRef.getDocument()

        guard snapshot.exists else { return nil }
        return try snapshot.data(as: SoundscapeRecord.self)
    }

    /// Fetch all records for a user
    func fetchRecords(userId: String, limit: Int = 100) async throws -> [SoundscapeRecord] {
        let snapshot = try await db.collection("soundscapes")
            .whereField("userId", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { doc in
            try doc.data(as: SoundscapeRecord.self)
        }
    }

    /// Fetch records updated since a given date
    func fetchRecordsUpdatedSince(_ date: Date, userId: String) async throws -> [SoundscapeRecord] {
        let snapshot = try await db.collection("soundscapes")
            .whereField("userId", isEqualTo: userId)
            .whereField("updated_at", isGreaterThan: Timestamp(date: date))
            .getDocuments()

        return try snapshot.documents.map { doc in
            try doc.data(as: SoundscapeRecord.self)
        }
    }

    /// Update a record
    func updateRecord(_ record: SoundscapeRecord) async throws {
        let docRef = db.collection("soundscapes").document(record.id)
        try await docRef.setData(from: record, merge: true)
    }

    /// Delete a record
    func deleteRecord(id: String) async throws {
        let docRef = db.collection("soundscapes").document(id)
        try await docRef.delete()
    }

    // MARK: - Evaluations

    /// Save an evaluation to Firestore
    func saveEvaluation(_ evaluation: SubjectiveEvaluation, userId: String) async throws {
        let docRef = db.collection("evaluations").document(evaluation.id)

        var data = try Firestore.Encoder().encode(evaluation)
        data["userId"] = userId

        try await docRef.setData(data)
    }

    /// Fetch evaluations for a record
    func fetchEvaluations(recordId: String) async throws -> [SubjectiveEvaluation] {
        let snapshot = try await db.collection("evaluations")
            .whereField("record_id", isEqualTo: recordId)
            .order(by: "created_at", descending: true)
            .getDocuments()

        return try snapshot.documents.map { doc in
            try doc.data(as: SubjectiveEvaluation.self)
        }
    }

    /// Fetch all evaluations for a user
    func fetchUserEvaluations(userId: String, limit: Int = 100) async throws -> [SubjectiveEvaluation] {
        let snapshot = try await db.collection("evaluations")
            .whereField("userId", isEqualTo: userId)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .getDocuments()

        return try snapshot.documents.map { doc in
            try doc.data(as: SubjectiveEvaluation.self)
        }
    }

    /// Delete an evaluation
    func deleteEvaluation(id: String) async throws {
        let docRef = db.collection("evaluations").document(id)
        try await docRef.delete()
    }
}
