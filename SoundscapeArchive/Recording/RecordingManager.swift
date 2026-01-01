import Foundation
import AVFoundation
import Accelerate

/// Core recording manager using AVAudioEngine
/// Records 44.1kHz/16bit/Mono WAV audio
@MainActor
@Observable
final class RecordingManager: NSObject {
    // MARK: - State

    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var duration: TimeInterval = 0
    private(set) var currentLevel: Float = -60  // dB
    private(set) var peakLevel: Float = -60

    // MARK: - Recording Settings

    private let sampleRate: Double = 44100
    private let channels: AVAudioChannelCount = 1
    private let bitDepth: Int = 16

    // MARK: - Audio Components

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?

    // MARK: - Timer

    private var durationTimer: Timer?
    private var startTime: Date?

    // MARK: - Waveform Data

    private(set) var waveformSamples: [Float] = []
    private let maxWaveformSamples = 200

    // MARK: - Recording Directory

    private var recordingsDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordings = documents.appendingPathComponent("recordings", isDirectory: true)

        if !FileManager.default.fileExists(atPath: recordings.path) {
            try? FileManager.default.createDirectory(at: recordings, withIntermediateDirectories: true)
        }

        return recordings
    }

    // MARK: - Public Methods

    /// Request microphone permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Check if microphone permission is granted
    var hasPermission: Bool {
        AVAudioApplication.shared.recordPermission == .granted
    }

    /// Start recording
    /// - Returns: URL of the recording file
    func startRecording() async throws -> URL {
        guard !isRecording else {
            throw RecordingError.alreadyRecording
        }

        guard hasPermission else {
            throw RecordingError.permissionDenied
        }

        // Configure audio session
        try configureAudioSession()

        // Generate file URL
        let recordId = SoundscapeRecord.generateId()
        let fileURL = recordingsDirectory.appendingPathComponent("\(recordId).wav")
        recordingURL = fileURL

        // Setup audio engine
        try setupAudioEngine(outputURL: fileURL)

        // Start engine
        try audioEngine?.start()

        // Update state
        isRecording = true
        isPaused = false
        duration = 0
        currentLevel = -60
        peakLevel = -60
        waveformSamples = []
        startTime = Date()

        // Start duration timer
        startDurationTimer()

        return fileURL
    }

    /// Stop recording
    /// - Returns: URL of the recorded file
    func stopRecording() async throws -> URL {
        guard isRecording else {
            throw RecordingError.notRecording
        }

        // Stop timer
        stopDurationTimer()

        // Stop engine
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        // Close file
        audioFile = nil

        // Update state
        isRecording = false
        isPaused = false

        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)

        guard let url = recordingURL else {
            throw RecordingError.noRecordingURL
        }

        return url
    }

    /// Pause recording
    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        audioEngine?.pause()
        isPaused = true
        stopDurationTimer()
    }

    /// Resume recording
    func resumeRecording() throws {
        guard isRecording, isPaused else { return }
        try audioEngine?.start()
        isPaused = false
        startDurationTimer()
    }

    /// Cancel recording (delete file)
    func cancelRecording() {
        stopDurationTimer()

        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioFile = nil

        // Delete file
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }

        recordingURL = nil
        isRecording = false
        isPaused = false
        duration = 0
        currentLevel = -60
        peakLevel = -60
        waveformSamples = []

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    // MARK: - Private Methods

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setPreferredSampleRate(sampleRate)
        try session.setActive(true)
    }

    private func setupAudioEngine(outputURL: URL) throws {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else {
            throw RecordingError.engineSetupFailed
        }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create output format (16-bit PCM)
        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: true
        ) else {
            throw RecordingError.formatCreationFailed
        }

        // Create audio file
        audioFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )

        // Install tap on input node
        let bufferSize: AVAudioFrameCount = 1024
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, inputFormat: inputFormat)
        }

        engine.prepare()
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        // Calculate RMS level
        var rms: Float = 0
        vDSP_measqv(channelData, 1, &rms, vDSP_Length(frameCount))
        rms = sqrt(rms)

        // Convert to dB
        let db = 20 * log10(max(rms, 1e-10))
        let calibratedDb = min(0, max(-60, db + 60))  // Normalize to -60 to 0 range

        // Update levels on main thread
        Task { @MainActor in
            self.currentLevel = calibratedDb
            self.peakLevel = max(self.peakLevel, calibratedDb)

            // Add to waveform samples
            if self.waveformSamples.count < self.maxWaveformSamples {
                self.waveformSamples.append(rms)
            } else {
                // Downsample by averaging pairs
                var newSamples: [Float] = []
                for i in stride(from: 0, to: self.waveformSamples.count - 1, by: 2) {
                    newSamples.append((self.waveformSamples[i] + self.waveformSamples[i + 1]) / 2)
                }
                newSamples.append(rms)
                self.waveformSamples = newSamples
            }
        }

        // Convert to Int16 and write to file
        do {
            // Create converter if needed
            guard let outputFormat = audioFile?.processingFormat else { return }

            if let converter = AVAudioConverter(from: inputFormat, to: outputFormat) {
                let ratio = outputFormat.sampleRate / inputFormat.sampleRate
                let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)

                guard let outputBuffer = AVAudioPCMBuffer(
                    pcmFormat: outputFormat,
                    frameCapacity: outputFrameCount
                ) else { return }

                var error: NSError?
                converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                    outStatus.pointee = .haveData
                    return buffer
                }

                if error == nil {
                    try audioFile?.write(from: outputBuffer)
                }
            }
        } catch {
            print("Error writing audio: \(error)")
        }
    }

    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [startTime = self.startTime] in
                guard let startTime = startTime else { return }
                self.duration = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
}

// MARK: - Recording Errors

enum RecordingError: Error, LocalizedError {
    case permissionDenied
    case alreadyRecording
    case notRecording
    case noRecordingURL
    case engineSetupFailed
    case formatCreationFailed
    case audioSessionFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "マイクへのアクセスが許可されていません"
        case .alreadyRecording:
            return "既に録音中です"
        case .notRecording:
            return "録音していません"
        case .noRecordingURL:
            return "録音ファイルのURLがありません"
        case .engineSetupFailed:
            return "オーディオエンジンのセットアップに失敗しました"
        case .formatCreationFailed:
            return "オーディオフォーマットの作成に失敗しました"
        case .audioSessionFailed:
            return "オーディオセッションの設定に失敗しました"
        }
    }
}
