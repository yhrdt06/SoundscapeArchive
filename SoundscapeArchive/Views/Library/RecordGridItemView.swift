import SwiftUI

/// Grid item view for recording grid
struct RecordGridItemView: View {
    let record: SoundscapeRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Waveform placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.1))
                    .aspectRatio(1.5, contentMode: .fit)

                VStack(spacing: 4) {
                    Image(systemName: "waveform")
                        .font(.largeTitle)
                        .foregroundStyle(.accent)

                    Text(formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Title
            Text(record.metadata.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)

            // Location and date
            VStack(alignment: .leading, spacing: 2) {
                if let location = record.metadata.locationName {
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                        Text(location)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Tags
            if !record.metadata.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(record.metadata.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .clipShape(Capsule())
                    }

                    if record.metadata.tags.count > 2 {
                        Text("+\(record.metadata.tags.count - 2)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Formatters

    private var formattedDuration: String {
        let minutes = Int(record.metadata.duration) / 60
        let seconds = Int(record.metadata.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: record.metadata.recordedAt)
    }
}

#Preview {
    let sampleRecord = SoundscapeRecord(
        id: "rec_sample",
        userId: "user1",
        metadata: SoundscapeMetadata(
            title: "渋谷駅前の音風景",
            recordedAt: Date(),
            duration: 185,
            location: GeoLocation(latitude: 35.6580, longitude: 139.7016),
            locationName: "渋谷区渋谷2丁目",
            equipment: Equipment(
                deviceModel: "iPhone 15 Pro",
                microphoneType: "内蔵マイク"
            ),
            tags: ["都市", "駅", "雑踏"]
        ),
        syncStatus: .synced
    )

    return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
        RecordGridItemView(record: sampleRecord)
        RecordGridItemView(record: sampleRecord)
    }
    .padding()
}
