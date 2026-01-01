import Foundation
import SwiftUI

/// ISO Circumplex quadrant classification
enum SoundscapeQuadrant: String, Codable, CaseIterable {
    case vibrant = "vibrant"        // High Pleasant, High Eventful
    case chaotic = "chaotic"        // Low Pleasant, High Eventful
    case monotonous = "monotonous"  // Low Pleasant, Low Eventful
    case calm = "calm"              // High Pleasant, Low Eventful

    var localizedName: String {
        switch self {
        case .vibrant: return "活気のある"
        case .chaotic: return "混沌とした"
        case .monotonous: return "単調な"
        case .calm: return "穏やかな"
        }
    }

    var englishName: String {
        switch self {
        case .vibrant: return "Vibrant"
        case .chaotic: return "Chaotic"
        case .monotonous: return "Monotonous"
        case .calm: return "Calm"
        }
    }

    var color: Color {
        switch self {
        case .vibrant: return .orange
        case .chaotic: return .red
        case .monotonous: return .gray
        case .calm: return .blue
        }
    }
}

/// Calculated ISO metrics from PAQ scores
/// Based on ISO/TS 12913-2 Circumplex Model
struct ISOMetrics: Codable, Equatable {
    /// ISO Pleasant dimension (approximately -1 to 1)
    let isoPleasant: Double

    /// ISO Eventful dimension (approximately -1 to 1)
    let isoEventful: Double

    /// Circumplex quadrant classification
    let quadrant: SoundscapeQuadrant

    enum CodingKeys: String, CodingKey {
        case isoPleasant = "iso_pleasant"
        case isoEventful = "iso_eventful"
        case quadrant
    }
}

/// Calculated sound source metrics
struct SourceMetrics: Codable, Equatable {
    /// Dominant sound source category
    let sourceDominant: String

    /// Natural sounds ratio (0-1)
    let naturalRatio: Double

    /// Shannon entropy of source distribution (0-2)
    let sourceEntropy: Double

    enum CodingKeys: String, CodingKey {
        case sourceDominant = "source_dominant"
        case naturalRatio = "natural_ratio"
        case sourceEntropy = "source_entropy"
    }
}

// MARK: - ISO Metrics Calculator
/// Calculates ISO/TS 12913-2 metrics from PAQ scores
struct ISOMetricsCalculator {
    /// cos(45°) = √2/2 ≈ 0.7071
    private static let cos45 = sqrt(2.0) / 2.0

    /// Normalization constant D = 4 + √32 ≈ 9.6569
    private static let D = 4.0 + sqrt(32.0)

    /// Calculate ISO metrics from PAQ scores
    /// - Parameter paq: PAQ 8-item scores (1-5 scale)
    /// - Returns: ISOMetrics with pleasant, eventful dimensions and quadrant
    static func calculate(from paq: PAQScores) -> ISOMetrics {
        let p = Double(paq.pleasant)
        let a = Double(paq.annoying)
        let c = Double(paq.calm)
        let ch = Double(paq.chaotic)
        let v = Double(paq.vibrant)
        let m = Double(paq.monotonous)
        let e = Double(paq.eventful)
        let ue = Double(paq.uneventful)

        // ISO Pleasant dimension
        // ISO_Pleasant = ((p - a) + cos45*(c - ch) + cos45*(v - m)) / D
        let isoPleasant = ((p - a) + cos45 * (c - ch) + cos45 * (v - m)) / D

        // ISO Eventful dimension
        // ISO_Eventful = ((e - ue) + cos45*(ch - c) + cos45*(v - m)) / D
        let isoEventful = ((e - ue) + cos45 * (ch - c) + cos45 * (v - m)) / D

        // Quadrant classification
        let quadrant = classifyQuadrant(pleasant: isoPleasant, eventful: isoEventful)

        return ISOMetrics(
            isoPleasant: round(isoPleasant * 10000) / 10000,
            isoEventful: round(isoEventful * 10000) / 10000,
            quadrant: quadrant
        )
    }

    /// Classify into quadrant based on ISO coordinates
    static func classifyQuadrant(pleasant: Double, eventful: Double) -> SoundscapeQuadrant {
        if pleasant >= 0 {
            return eventful >= 0 ? .vibrant : .calm
        } else {
            return eventful >= 0 ? .chaotic : .monotonous
        }
    }
}

// MARK: - Source Metrics Calculator
/// Calculates sound source related metrics
struct SourceMetricsCalculator {
    /// Calculate source metrics from perception values
    static func calculate(from sources: SoundSourcePerception) -> SourceMetrics {
        let sourceValues: [String: Double] = [
            "traffic": sources.traffic,
            "other": sources.other,
            "human": sources.human,
            "natural": sources.natural
        ]

        // Dominant source
        let sourceDominant = sourceValues.max(by: { $0.value < $1.value })?.key ?? "natural"

        // Natural ratio
        let total = sourceValues.values.reduce(0, +)
        let eps = 1e-12
        let naturalRatio = total > 0 ? sources.natural / (total + eps) : 0

        // Shannon entropy (normalized: 0-1)
        var sourceEntropy = 0.0
        if total > 0 {
            for value in sourceValues.values where value > 0 {
                let p = value / total
                sourceEntropy -= p * log2(p)
            }
            // Normalize by max entropy (log2(4) = 2)
            sourceEntropy /= log2(4.0)
        }

        return SourceMetrics(
            sourceDominant: sourceDominant,
            naturalRatio: round(naturalRatio * 10000) / 10000,
            sourceEntropy: round(sourceEntropy * 10000) / 10000
        )
    }
}
