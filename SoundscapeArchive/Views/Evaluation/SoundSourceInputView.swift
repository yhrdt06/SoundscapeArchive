import SwiftUI

/// Sound source perception input view
struct SoundSourceInputView: View {
    @Binding var sources: SoundSourcePerception

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("音源知覚")
                    .font(.headline)

                Text("どのような音がどの程度聞こえましたか？各項目を0〜10で評価してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Sound source sliders
            VStack(spacing: 20) {
                SourceSliderView(
                    icon: "car.fill",
                    label: "交通音",
                    description: "車、電車、飛行機など",
                    value: $sources.traffic
                )

                SourceSliderView(
                    icon: "person.2.fill",
                    label: "人の音",
                    description: "話し声、足音、活動音など",
                    value: $sources.human
                )

                SourceSliderView(
                    icon: "leaf.fill",
                    label: "自然音",
                    description: "鳥、水、風、虫など",
                    value: $sources.natural
                )

                SourceSliderView(
                    icon: "wrench.and.screwdriver.fill",
                    label: "その他の音",
                    description: "機械音、音楽など",
                    value: $sources.other
                )
            }

            // Summary
            if sources.isValid {
                VStack(alignment: .leading, spacing: 8) {
                    Text("音源構成")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    SourceBarChart(sources: sources)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Slider for a single sound source
private struct SourceSliderView: View {
    let icon: String
    let label: String
    let description: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.accent)
                    .frame(width: 20)

                Text(label)
                    .font(.subheadline)

                Spacer()

                Text(String(format: "%.0f", value))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .monospacedDigit()
                    .frame(width: 24)
            }

            Text(description)
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 8) {
                Text("0")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Slider(value: $value, in: 0...10, step: 1)
                    .tint(.accentColor)

                Text("10")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// Bar chart showing source composition
private struct SourceBarChart: View {
    let sources: SoundSourcePerception

    private var total: Double {
        sources.traffic + sources.human + sources.natural + sources.other
    }

    var body: some View {
        HStack(spacing: 2) {
            if total > 0 {
                BarSegment(
                    value: sources.traffic,
                    total: total,
                    color: .red,
                    label: "交通"
                )
                BarSegment(
                    value: sources.human,
                    total: total,
                    color: .orange,
                    label: "人"
                )
                BarSegment(
                    value: sources.natural,
                    total: total,
                    color: .green,
                    label: "自然"
                )
                BarSegment(
                    value: sources.other,
                    total: total,
                    color: .blue,
                    label: "他"
                )
            } else {
                Text("まだ入力がありません")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 24)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct BarSegment: View {
    let value: Double
    let total: Double
    let color: Color
    let label: String

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return value / total
    }

    var body: some View {
        if percentage > 0.05 {
            GeometryReader { geo in
                ZStack {
                    Rectangle()
                        .fill(color)

                    if percentage > 0.15 {
                        Text(label)
                            .font(.caption2)
                            .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: percentage > 0 ? nil : 0)
            .layoutPriority(percentage)
        }
    }
}

struct SoundSourceInputViewPreview: View {
    @State private var sources = SoundSourcePerception(
        traffic: 3.0, other: 2.0, human: 5.0, natural: 7.0
    )

    var body: some View {
        ScrollView {
            SoundSourceInputView(sources: $sources)
                .padding()
        }
    }
}

#Preview {
    SoundSourceInputViewPreview()
}
