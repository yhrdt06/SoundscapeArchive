import Foundation

/// Metadata for a soundscape recording
struct SoundscapeMetadata: Codable, Equatable {
    /// Recording title (required, max 200 chars)
    var title: String

    /// Description (max 2000 chars)
    var description: String?

    /// GPS location
    var location: GeoLocation

    /// Recording timestamp
    var recordedAt: Date

    /// Duration in seconds
    var duration: Double

    /// Sample rate (Hz)
    var sampleRate: Int

    /// Number of channels
    var channels: Int

    /// Bit depth
    var bitDepth: Int

    /// File format
    var fileFormat: FileFormat

    /// File size in bytes
    var fileSize: Int

    /// Tags for categorization
    var tags: [String]

    /// Human-readable location name
    var locationName: String?

    /// Weather conditions
    var weather: String?

    /// Temperature in Celsius
    var temperature: Double?

    /// Additional notes (max 5000 chars)
    var notes: String?

    /// Equipment information
    var equipment: Equipment?

    enum CodingKeys: String, CodingKey {
        case title, description, location
        case recordedAt = "recorded_at"
        case duration
        case sampleRate = "sample_rate"
        case channels
        case bitDepth = "bit_depth"
        case fileFormat = "file_format"
        case fileSize = "file_size"
        case tags
        case locationName = "location_name"
        case weather, temperature, notes, equipment
    }

    init(
        title: String,
        description: String? = nil,
        location: GeoLocation = GeoLocation(latitude: 0, longitude: 0),
        recordedAt: Date,
        duration: Double,
        sampleRate: Int = 44100,
        channels: Int = 1,
        bitDepth: Int = 16,
        fileFormat: FileFormat = .wav,
        fileSize: Int = 0,
        tags: [String] = [],
        locationName: String? = nil,
        weather: String? = nil,
        temperature: Double? = nil,
        notes: String? = nil,
        equipment: Equipment? = nil
    ) {
        self.title = title
        self.description = description
        self.location = location
        self.recordedAt = recordedAt
        self.duration = duration
        self.sampleRate = sampleRate
        self.channels = channels
        self.bitDepth = bitDepth
        self.fileFormat = fileFormat
        self.fileSize = fileSize
        self.tags = tags
        self.locationName = locationName
        self.weather = weather
        self.temperature = temperature
        self.notes = notes
        self.equipment = equipment
    }

    /// Formatted duration string (MM:SS or HH:MM:SS)
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    /// Formatted file size string
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
}
