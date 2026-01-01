import SwiftUI

/// View showing detailed evaluation results
struct EvaluationResultView: View {
    let isoMetrics: ISOMetrics
    let sourceMetrics: SourceMetrics
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Circumplex chart
                    circumplexSection

                    // ISO metrics detail
                    isoMetricsSection

                    // Source metrics
                    sourceMetricsSection

                    // Interpretation
                    interpretationSection
                }
                .padding()
            }
            .navigationTitle("評価結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Circumplex Section

    private var circumplexSection: some View {
        VStack(spacing: 16) {
            Text("サーカンプレックス図")
                .font(.headline)

            CircumplexChartView(isoMetrics: isoMetrics, size: 280)

            // Quadrant badge
            HStack {
                Text("象限:")
                    .foregroundStyle(.secondary)

                Text(isoMetrics.quadrant.rawValue)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(quadrantColor.opacity(0.2))
                    .foregroundStyle(quadrantColor)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var quadrantColor: Color {
        switch isoMetrics.quadrant {
        case .vibrant: return .orange
        case .chaotic: return .red
        case .monotonous: return .gray
        case .calm: return .green
        }
    }

    // MARK: - ISO Metrics Section

    private var isoMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ISO指標")
                .font(.headline)

            VStack(spacing: 12) {
                MetricRow(
                    label: "ISO Pleasant",
                    value: isoMetrics.isoPleasant,
                    description: "心地よさ (-1 〜 +1)",
                    positiveColor: .green,
                    negativeColor: .red
                )

                MetricRow(
                    label: "ISO Eventful",
                    value: isoMetrics.isoEventful,
                    description: "活動性 (-1 〜 +1)",
                    positiveColor: .orange,
                    negativeColor: .blue
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Source Metrics Section

    private var sourceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("音源分析")
                .font(.headline)

            VStack(spacing: 12) {
                // Dominant source
                HStack {
                    Text("支配的な音源")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(sourceName(sourceMetrics.sourceDominant))
                        .fontWeight(.medium)
                }

                Divider()

                // Natural ratio
                SourceRatioBar(
                    label: "自然音",
                    ratio: sourceMetrics.naturalRatio,
                    color: .green
                )

                // Source entropy
                HStack {
                    Text("音源エントロピー")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(String(format: "%.2f", sourceMetrics.sourceEntropy))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sourceName(_ source: String) -> String {
        switch source {
        case "natural": return "自然音"
        case "human": return "人の音"
        case "traffic": return "交通音"
        case "other": return "その他"
        default: return source
        }
    }

    // MARK: - Interpretation Section

    private var interpretationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("解釈")
                .font(.headline)

            Text(interpretationText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var interpretationText: String {
        var text = ""

        // Quadrant interpretation
        switch isoMetrics.quadrant {
        case .vibrant:
            text += "この音環境は「活気のある」空間として評価されました。心地よさと活動性の両方が高く、エネルギッシュでポジティブな印象を与えています。"
        case .chaotic:
            text += "この音環境は「混沌とした」空間として評価されました。活動性は高いですが、心地よさが低く、騒がしい印象を与えています。"
        case .monotonous:
            text += "この音環境は「単調な」空間として評価されました。心地よさと活動性の両方が低く、退屈な印象を与えています。"
        case .calm:
            text += "この音環境は「穏やかな」空間として評価されました。心地よさが高く活動性が低い、リラックスできる環境です。"
        }

        // Source interpretation
        if sourceMetrics.naturalRatio > 0.5 {
            text += "\n\n自然音が支配的であり、一般的に心地よいと感じられる音環境です。"
        } else if sourceMetrics.sourceDominant == "traffic" {
            text += "\n\n交通音が支配的であり、都市的な音環境の特徴を持っています。"
        }

        return text
    }
}

// MARK: - Metric Row

private struct MetricRow: View {
    let label: String
    let value: Double
    let description: String
    let positiveColor: Color
    let negativeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(String(format: "%+.3f", value))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(value >= 0 ? positiveColor : negativeColor)
            }

            // Bar visualization
            GeometryReader { geo in
                ZStack(alignment: value >= 0 ? .leading : .trailing) {
                    // Background
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))

                    // Value bar
                    Rectangle()
                        .fill(value >= 0 ? positiveColor : negativeColor)
                        .frame(width: abs(value) * geo.size.width / 2)
                        .offset(x: value >= 0 ? geo.size.width / 2 : geo.size.width / 2 - abs(value) * geo.size.width / 2)

                    // Center line
                    Rectangle()
                        .fill(Color.primary.opacity(0.3))
                        .frame(width: 2)
                        .offset(x: geo.size.width / 2 - 1)
                }
            }
            .frame(height: 8)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(description)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Source Ratio Bar

private struct SourceRatioBar: View {
    let label: String
    let ratio: Double
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))

                    Rectangle()
                        .fill(color)
                        .frame(width: ratio * geo.size.width)
                }
            }
            .frame(height: 16)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            Text(String(format: "%.0f%%", ratio * 100))
                .font(.caption)
                .monospacedDigit()
                .frame(width: 40, alignment: .trailing)
        }
    }
}

#Preview {
    EvaluationResultView(
        isoMetrics: ISOMetrics(
            isoPleasant: 0.35,
            isoEventful: 0.28,
            quadrant: .vibrant
        ),
        sourceMetrics: SourceMetrics(
            sourceDominant: "natural",
            naturalRatio: 0.45,
            sourceEntropy: 0.85
        )
    )
}
