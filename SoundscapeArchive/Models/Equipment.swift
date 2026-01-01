import Foundation

/// Equipment information for recording
struct Equipment: Codable, Equatable {
    /// Microphone model
    var microphone: String?

    /// Recorder model
    var recorder: String?

    /// Preamp model
    var preamp: String?

    /// Calibration info
    var calibration: String?

    /// Other equipment notes
    var other: String?

    init(
        microphone: String? = nil,
        recorder: String? = nil,
        preamp: String? = nil,
        calibration: String? = nil,
        other: String? = nil
    ) {
        self.microphone = microphone
        self.recorder = recorder
        self.preamp = preamp
        self.calibration = calibration
        self.other = other
    }

    /// Check if any equipment info is set
    var hasInfo: Bool {
        microphone != nil || recorder != nil || preamp != nil ||
        calibration != nil || other != nil
    }
}
