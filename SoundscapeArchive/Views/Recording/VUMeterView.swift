import SwiftUI

/// VU Meter display for audio level
struct VUMeterView: View {
    let level: Float  // -60 to 0 dB
    let peak: Float   // -60 to 0 dB

    // Meter configuration
    private let minDB: Float = -60
    private let maxDB: Float = 0
    private let warningDB: Float = -12
    private let dangerDB: Float = -6

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.1))

                // Level bar
                levelBar(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Peak indicator
                peakIndicator(height: height)

                // Scale marks
                scaleMarks(height: height)
            }
            .frame(width: width, height: height)
        }
    }

    // MARK: - Level Bar

    private func levelBar(height: CGFloat) -> some View {
        let normalizedLevel = normalizeDB(level)
        let barHeight = CGFloat(normalizedLevel) * height

        return VStack(spacing: 0) {
            Spacer()

            Rectangle()
                .fill(levelGradient)
                .frame(height: barHeight)
                .animation(.easeOut(duration: 0.05), value: level)
        }
    }

    private var levelGradient: LinearGradient {
        LinearGradient(
            colors: [.green, .green, .yellow, .orange, .red],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    // MARK: - Peak Indicator

    private func peakIndicator(height: CGFloat) -> some View {
        let normalizedPeak = normalizeDB(peak)
        let peakPosition = height - (CGFloat(normalizedPeak) * height)

        return VStack {
            Spacer()
                .frame(height: peakPosition - 2)

            Rectangle()
                .fill(peakColor)
                .frame(height: 4)

            Spacer()
        }
    }

    private var peakColor: Color {
        if peak >= dangerDB {
            return .red
        } else if peak >= warningDB {
            return .orange
        } else {
            return .green
        }
    }

    // MARK: - Scale Marks

    private func scaleMarks(height: CGFloat) -> some View {
        let marks: [Float] = [0, -6, -12, -24, -36, -48, -60]

        return ZStack(alignment: .trailing) {
            ForEach(marks, id: \.self) { db in
                let normalized = normalizeDB(db)
                let yPosition = height - (CGFloat(normalized) * height)

                HStack {
                    Spacer()

                    Text("\(Int(db))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Rectangle()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 8, height: 1)
                }
                .offset(y: yPosition - height / 2)
            }
        }
        .padding(.trailing, 4)
    }

    // MARK: - Helper

    private func normalizeDB(_ db: Float) -> Float {
        let clamped = max(minDB, min(maxDB, db))
        return (clamped - minDB) / (maxDB - minDB)
    }
}

#Preview {
    VStack(spacing: 40) {
        VUMeterView(level: -20, peak: -10)
            .frame(width: 60, height: 300)

        VUMeterView(level: -6, peak: -3)
            .frame(width: 60, height: 300)

        VUMeterView(level: -40, peak: -30)
            .frame(width: 60, height: 300)
    }
    .padding()
}
