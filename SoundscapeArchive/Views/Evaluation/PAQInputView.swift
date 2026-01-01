import SwiftUI

/// PAQ (Perceived Affective Quality) 8-item questionnaire input view
struct PAQInputView: View {
    @Binding var paqScores: PAQScores
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("主観評価 (PAQ)")
                    .font(.headline)

                Text("この音環境についてどのように感じましたか？各項目を1〜5で評価してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // PAQ items in pairs (opposing attributes)
            VStack(spacing: 20) {
                PAQItemPair(
                    leftLabel: "Pleasant\n(心地よい)",
                    leftValue: $paqScores.pleasant,
                    rightLabel: "Annoying\n(煩わしい)",
                    rightValue: $paqScores.annoying
                )

                PAQItemPair(
                    leftLabel: "Vibrant\n(活気のある)",
                    leftValue: $paqScores.vibrant,
                    rightLabel: "Monotonous\n(単調な)",
                    rightValue: $paqScores.monotonous
                )

                PAQItemPair(
                    leftLabel: "Calm\n(穏やかな)",
                    leftValue: $paqScores.calm,
                    rightLabel: "Chaotic\n(混沌とした)",
                    rightValue: $paqScores.chaotic
                )

                PAQItemPair(
                    leftLabel: "Eventful\n(変化に富む)",
                    leftValue: $paqScores.eventful,
                    rightLabel: "Uneventful\n(変化のない)",
                    rightValue: $paqScores.uneventful
                )
            }

            // Validation status
            if paqScores.isValid {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("すべての項目が入力されました")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// A pair of opposing PAQ attributes
private struct PAQItemPair: View {
    let leftLabel: String
    @Binding var leftValue: Int
    let rightLabel: String
    @Binding var rightValue: Int

    var body: some View {
        HStack(spacing: 12) {
            // Left attribute
            PAQItemView(label: leftLabel, value: $leftValue)

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)
                .frame(maxHeight: .infinity)

            // Right attribute
            PAQItemView(label: rightLabel, value: $rightValue)
        }
    }
}

/// Single PAQ item with rating selector
private struct PAQItemView: View {
    let label: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text(label)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(height: 36)

            // Rating buttons (1-5)
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        value = rating
                    } label: {
                        Text("\(rating)")
                            .font(.caption)
                            .fontWeight(value == rating ? .bold : .regular)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(value == rating ? Color.accentColor : Color(.systemGray5))
                            )
                            .foregroundStyle(value == rating ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    @Previewable @State var scores = PAQScores(
        pleasant: 4, chaotic: 2, vibrant: 3, uneventful: 2,
        calm: 4, annoying: 2, eventful: 3, monotonous: 2
    )

    return ScrollView {
        PAQInputView(paqScores: $scores)
            .padding()
    }
}
