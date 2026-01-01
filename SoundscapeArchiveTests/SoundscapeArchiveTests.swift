import XCTest
@testable import SoundscapeArchive

final class SoundscapeArchiveTests: XCTestCase {

    // MARK: - GeoLocation Tests

    func testGeoLocationValidation() throws {
        let validLocation = GeoLocation(latitude: 35.6812, longitude: 139.7671)
        XCTAssertTrue(validLocation.isValid)

        let invalidLatitude = GeoLocation(latitude: 100, longitude: 0)
        XCTAssertFalse(invalidLatitude.isValid)

        let invalidLongitude = GeoLocation(latitude: 0, longitude: 200)
        XCTAssertFalse(invalidLongitude.isValid)
    }

    // MARK: - PAQScores Tests

    func testPAQScoresValidation() throws {
        let validScores = PAQScores(
            pleasant: 4, chaotic: 2, vibrant: 3, uneventful: 2,
            calm: 4, annoying: 2, eventful: 3, monotonous: 2
        )
        XCTAssertTrue(validScores.isValid)

        let invalidScores = PAQScores(
            pleasant: 6, chaotic: 2, vibrant: 3, uneventful: 2,
            calm: 4, annoying: 2, eventful: 3, monotonous: 2
        )
        XCTAssertFalse(invalidScores.isValid)
    }

    // MARK: - ISOMetrics Calculator Tests

    func testISOMetricsCalculation() throws {
        // Test with known values
        let paq = PAQScores(
            pleasant: 4, chaotic: 2, vibrant: 4, uneventful: 2,
            calm: 4, annoying: 2, eventful: 3, monotonous: 2
        )

        let metrics = ISOMetricsCalculator.calculate(from: paq)

        // Should be in the "vibrant" quadrant (high pleasant, high eventful)
        XCTAssertGreaterThan(metrics.isoPleasant, 0)
        XCTAssertEqual(metrics.quadrant, .vibrant)
    }

    func testQuadrantClassification() throws {
        XCTAssertEqual(ISOMetricsCalculator.classifyQuadrant(pleasant: 0.5, eventful: 0.5), .vibrant)
        XCTAssertEqual(ISOMetricsCalculator.classifyQuadrant(pleasant: -0.5, eventful: 0.5), .chaotic)
        XCTAssertEqual(ISOMetricsCalculator.classifyQuadrant(pleasant: -0.5, eventful: -0.5), .monotonous)
        XCTAssertEqual(ISOMetricsCalculator.classifyQuadrant(pleasant: 0.5, eventful: -0.5), .calm)
    }

    // MARK: - SourceMetrics Calculator Tests

    func testSourceMetricsCalculation() throws {
        let sources = SoundSourcePerception(
            traffic: 2.0, other: 1.0, human: 3.0, natural: 7.0
        )

        let metrics = SourceMetricsCalculator.calculate(from: sources)

        XCTAssertEqual(metrics.sourceDominant, "natural")
        XCTAssertGreaterThan(metrics.naturalRatio, 0.5)
    }

    // MARK: - SoundscapeRecord Tests

    func testRecordIdGeneration() throws {
        let id1 = SoundscapeRecord.generateId()
        let id2 = SoundscapeRecord.generateId()

        XCTAssertTrue(id1.hasPrefix("rec_"))
        XCTAssertTrue(id2.hasPrefix("rec_"))
        XCTAssertNotEqual(id1, id2)
    }

    func testSoundscapeRecordCreation() throws {
        let metadata = SoundscapeMetadata(
            title: "Test Recording",
            recordedAt: Date(),
            duration: 60.0
        )

        let record = SoundscapeRecord(
            userId: "test_user",
            metadata: metadata
        )

        XCTAssertTrue(record.id.hasPrefix("rec_"))
        XCTAssertEqual(record.userId, "test_user")
        XCTAssertEqual(record.metadata.title, "Test Recording")
        XCTAssertNil(record.acousticAnalysis)
        XCTAssertNil(record.evaluation)
        XCTAssertEqual(record.syncStatus, .pendingUpload)
    }
}
