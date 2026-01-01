import SwiftUI

/// Waveform preview display during recording
struct WaveformPreviewView: View {
    let samples: [Float]

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawWaveform(context: context, size: size)
            }
        }
    }

    private func drawWaveform(context: GraphicsContext, size: CGSize) {
        guard !samples.isEmpty else { return }

        let width = size.width
        let height = size.height
        let midY = height / 2
        let barWidth = width / CGFloat(samples.count)

        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * barWidth
            let barHeight = CGFloat(sample) * height * 0.8

            let rect = CGRect(
                x: x,
                y: midY - barHeight / 2,
                width: max(barWidth - 1, 1),
                height: max(barHeight, 1)
            )

            let path = Path(roundedRect: rect, cornerRadius: 1)
            context.fill(path, with: .color(.blue.opacity(0.7)))
        }
    }
}

/// Waveform view with playback progress
struct WaveformPlayerView: View {
    let samples: [Double]
    let progress: Double  // 0.0 to 1.0
    var playedColor: Color = .blue
    var unplayedColor: Color = .gray.opacity(0.3)

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawWaveform(context: context, size: size)
            }
        }
    }

    private func drawWaveform(context: GraphicsContext, size: CGSize) {
        guard !samples.isEmpty else { return }

        let width = size.width
        let height = size.height
        let midY = height / 2
        let barWidth = width / CGFloat(samples.count)

        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * barWidth
            let barHeight = CGFloat(sample) * height * 0.8

            let isPlayed = Double(index) / Double(samples.count) <= progress
            let color = isPlayed ? playedColor : unplayedColor

            let rect = CGRect(
                x: x,
                y: midY - barHeight / 2,
                width: max(barWidth - 1, 1),
                height: max(barHeight, 2)
            )

            let path = Path(roundedRect: rect, cornerRadius: 1)
            context.fill(path, with: .color(color))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Recording waveform
        WaveformPreviewView(samples: (0..<50).map { _ in Float.random(in: 0.1...1.0) })
            .frame(height: 80)
            .padding()
            .background(Color.black.opacity(0.05))
            .cornerRadius(8)

        // Player waveform
        WaveformPlayerView(
            samples: (0..<100).map { _ in Double.random(in: 0.1...1.0) },
            progress: 0.4
        )
        .frame(height: 60)
        .padding()
        .background(Color.black.opacity(0.05))
        .cornerRadius(8)
    }
    .padding()
}
