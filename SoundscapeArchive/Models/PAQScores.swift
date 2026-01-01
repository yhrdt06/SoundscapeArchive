import Foundation

/// PAQ 8-item ratings (1-5 Likert scale)
/// Based on ISO/TS 12913-2 Method A
struct PAQScores: Codable, Equatable {
    /// Pleasant (心地よい) - 1 to 5
    var pleasant: Int

    /// Chaotic (混沌としている) - 1 to 5
    var chaotic: Int

    /// Vibrant (活気がある) - 1 to 5
    var vibrant: Int

    /// Uneventful (変化が少ない) - 1 to 5
    var uneventful: Int

    /// Calm (落ち着いている) - 1 to 5
    var calm: Int

    /// Annoying (わずらわしい) - 1 to 5
    var annoying: Int

    /// Eventful (出来事が多い) - 1 to 5
    var eventful: Int

    /// Monotonous (単調だ) - 1 to 5
    var monotonous: Int

    init(
        pleasant: Int = 3,
        chaotic: Int = 3,
        vibrant: Int = 3,
        uneventful: Int = 3,
        calm: Int = 3,
        annoying: Int = 3,
        eventful: Int = 3,
        monotonous: Int = 3
    ) {
        self.pleasant = pleasant
        self.chaotic = chaotic
        self.vibrant = vibrant
        self.uneventful = uneventful
        self.calm = calm
        self.annoying = annoying
        self.eventful = eventful
        self.monotonous = monotonous
    }

    /// Validate all scores are within 1-5 range
    var isValid: Bool {
        let scores = [pleasant, chaotic, vibrant, uneventful, calm, annoying, eventful, monotonous]
        return scores.allSatisfy { (1...5).contains($0) }
    }

    /// All PAQ item labels in Japanese
    static let labels: [(key: String, japanese: String, english: String)] = [
        ("pleasant", "心地よい", "Pleasant"),
        ("chaotic", "混沌としている", "Chaotic"),
        ("vibrant", "活気がある", "Vibrant"),
        ("uneventful", "変化が少ない", "Uneventful"),
        ("calm", "落ち着いている", "Calm"),
        ("annoying", "わずらわしい", "Annoying"),
        ("eventful", "出来事が多い", "Eventful"),
        ("monotonous", "単調だ", "Monotonous")
    ]
}
