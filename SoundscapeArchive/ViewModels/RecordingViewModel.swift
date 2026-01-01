import Foundation
import SwiftUI
import SwiftData

/// ViewModel for recording screen
@MainActor
@Observable
final class RecordingViewModel {
    // MARK: - Dependencies

    private let recordingManager = RecordingManager()
    private let locationManager = LocationManager()
    private var modelContext: ModelContext?

    // MARK: - State

    private(set) var recordingState: RecordingState = .idle
    private(set) var recordedURL: URL?
    private(set) var capturedLocation: GeoLocation?
    private(set) var error: Error?
    private(set) var showError = false

    // Recording info
    var isRecording: Bool { recordingManager.isRecording }
    var isPaused: Bool { recordingManager.isPaused }
    var duration: TimeInterval { recordingManager.duration }
    var currentLevel: Float { recordingManager.currentLevel }
    var peakLevel: Float { recordingManager.peakLevel }
    var waveformSamples: [Float] { recordingManager.waveformSamples }

    // Location info
    var hasLocationPermission: Bool { locationManager.hasPermission }
    var locationStatus: CLAuthorizationStatus { locationManager.authorizationStatus }
    var currentLocation: GeoLocation? { locationManager.toGeoLocation() }

    // Microphone permission
    var hasMicrophonePermission: Bool { recordingManager.hasPermission }

    // MARK: - Recording State

    enum RecordingState {
        case idle
        case preparing
        case recording
        case paused
        case processing
        case completed(SoundscapeRecord)
        case error(Error)
    }

    // MARK: - Init

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Permissions

    func requestPermissions() async {
        // Request microphone permission
        _ = await recordingManager.requestPermission()

        // Request location permission
        locationManager.requestPermission()
    }

    // MARK: - Recording Controls

    func startRecording() async {
        recordingState = .preparing

        // Start location updates
        locationManager.startUpdating()

        do {
            let url = try await recordingManager.startRecording()
            recordedURL = url
            capturedLocation = locationManager.toGeoLocation()
            recordingState = .recording
        } catch {
            self.error = error
            self.showError = true
            recordingState = .error(error)
        }
    }

    func stopRecording() async {
        recordingState = .processing

        do {
            let url = try await recordingManager.stopRecording()
            locationManager.stopUpdating()

            // Create record
            let record = createRecord(audioURL: url)

            // Save to local storage
            if let context = modelContext {
                try await saveRecord(record, audioPath: url.path, context: context)
            }

            recordingState = .completed(record)
        } catch {
            self.error = error
            self.showError = true
            recordingState = .error(error)
        }
    }

    func pauseRecording() {
        recordingManager.pauseRecording()
        recordingState = .paused
    }

    func resumeRecording() {
        do {
            try recordingManager.resumeRecording()
            recordingState = .recording
        } catch {
            self.error = error
            self.showError = true
        }
    }

    func cancelRecording() {
        recordingManager.cancelRecording()
        locationManager.stopUpdating()
        recordedURL = nil
        capturedLocation = nil
        recordingState = .idle
    }

    func resetState() {
        recordingState = .idle
        recordedURL = nil
        error = nil
        showError = false
    }

    // MARK: - Private Methods

    private func createRecord(audioURL: URL) -> SoundscapeRecord {
        guard let userId = AuthManager.shared.userId else {
            fatalError("User not logged in")
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int) ?? 0

        let location = capturedLocation ?? GeoLocation(latitude: 0, longitude: 0)

        let metadata = SoundscapeMetadata(
            title: "録音 \(formattedDate())",
            description: nil,
            location: location,
            recordedAt: Date(),
            duration: duration,
            sampleRate: 44100,
            channels: 1,
            bitDepth: 16,
            fileFormat: .wav,
            fileSize: fileSize,
            tags: [],
            locationName: nil,
            weather: nil,
            temperature: nil,
            notes: nil,
            equipment: nil
        )

        // Generate waveform preview (normalized)
        let normalizedWaveform = normalizeWaveform(waveformSamples)

        return SoundscapeRecord(
            id: SoundscapeRecord.generateId(),
            userId: userId,
            metadata: metadata,
            acousticAnalysis: nil,
            evaluation: nil,
            audioFilePath: nil,
            waveformPreview: normalizedWaveform.map { Double($0) },
            createdAt: Date(),
            updatedAt: Date(),
            syncStatus: .pendingUpload
        )
    }

    private func saveRecord(_ record: SoundscapeRecord, audioPath: String, context: ModelContext) async throws {
        let localRecord = try LocalSoundscapeRecord.from(record, localAudioPath: audioPath)
        context.insert(localRecord)
        try context.save()
    }

    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: Date())
    }

    private func normalizeWaveform(_ samples: [Float]) -> [Float] {
        guard !samples.isEmpty else { return [] }

        let maxValue = samples.max() ?? 1.0
        guard maxValue > 0 else { return samples.map { _ in 0.0 } }

        return samples.map { $0 / maxValue }
    }
}

// MARK: - Formatted Duration

extension RecordingViewModel {
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let tenths = Int((duration - Double(totalSeconds)) * 10)
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}
