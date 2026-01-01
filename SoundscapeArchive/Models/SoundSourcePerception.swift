import Foundation

/// Sound source category perception (0-10 scale)
struct SoundSourcePerception: Codable, Equatable {
    /// Traffic noise perception (交通騒音)
    var traffic: Double

    /// Other mechanical/industrial sounds (その他の機械音・産業音)
    var other: Double

    /// Human sounds - voices, footsteps (人の声・足音)
    var human: Double

    /// Natural sounds - birds, water, wind (自然音)
    var natural: Double

    init(
        traffic: Double = 5.0,
        other: Double = 5.0,
        human: Double = 5.0,
        natural: Double = 5.0
    ) {
        self.traffic = traffic
        self.other = other
        self.human = human
        self.natural = natural
    }

    /// Validate all values are within 0-10 range
    var isValid: Bool {
        let values = [traffic, other, human, natural]
        return values.allSatisfy { (0...10).contains($0) }
    }

    /// Total of all perception values
    var total: Double {
        traffic + other + human + natural
    }

    /// Get the dominant sound source category
    var dominantSource: String {
        let sources: [(String, Double)] = [
            ("traffic", traffic),
            ("other", other),
            ("human", human),
            ("natural", natural)
        ]
        return sources.max(by: { $0.1 < $1.1 })?.0 ?? "natural"
    }

    /// Calculate natural sounds ratio
    var naturalRatio: Double {
        guard total > 0 else { return 0 }
        return natural / total
    }

    /// Source category labels
    static let labels: [(key: String, japanese: String, english: String)] = [
        ("traffic", "交通騒音", "Traffic"),
        ("other", "その他の機械音", "Other"),
        ("human", "人の声・足音", "Human"),
        ("natural", "自然音", "Natural")
    ]
}
