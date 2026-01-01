import Foundation

/// Frequency spectrum data
struct SpectrumData: Codable, Equatable {
    let frequencies: [Double]
    let magnitude: [Double]
}

/// Octave band analysis data
struct OctaveBandData: Codable, Equatable {
    let frequencies: [Double]
    let levels: [Double]

    /// Standard 1/1 octave band center frequencies
    static let standardFrequencies: [Double] = [
        31.5, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000
    ]
}

/// Time history of sound levels
struct TimeHistoryData: Codable, Equatable {
    let times: [Double]
    let levels: [Double]
}

/// Spectrogram data (time-frequency representation)
struct SpectrogramData: Codable, Equatable {
    let times: [Double]
    let frequencies: [Double]
    let magnitude: [[Double]]  // 2D array [freq x time]
}

/// Acoustic analysis results
/// Calculated on server side after audio upload
struct AcousticAnalysis: Codable, Equatable {
    /// A-weighted equivalent continuous sound level (dB)
    let laeq: Double

    /// Maximum sound level (dB)
    let lmax: Double

    /// Minimum sound level (dB)
    let lmin: Double

    /// 10% exceedance level (dB)
    let l10: Double

    /// 50% exceedance level / median (dB)
    let l50: Double

    /// 90% exceedance level (dB)
    let l90: Double

    /// Frequency spectrum data
    let spectrum: SpectrumData

    /// Octave band levels
    let octaveBands: OctaveBandData

    /// Time history data (optional)
    let timeHistory: TimeHistoryData?

    /// Spectrogram data (optional)
    let spectrogram: SpectrogramData?

    enum CodingKeys: String, CodingKey {
        case laeq, lmax, lmin, l10, l50, l90
        case spectrum
        case octaveBands = "octave_bands"
        case timeHistory = "time_history"
        case spectrogram
    }

    /// Dynamic range (Lmax - Lmin)
    var dynamicRange: Double {
        lmax - lmin
    }

    /// Background level indicator (L90)
    var backgroundLevel: Double {
        l90
    }
}
