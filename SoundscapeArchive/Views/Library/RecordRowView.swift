import SwiftUI

/// Row view for recording list
struct RecordRowView: View {
    let record: SoundscapeRecord

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail or icon
            thumbnailView

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(record.metadata.title)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Location
                    if let location = record.metadata.locationName {
                        Label(location, systemImage: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    // Duration
                    Label(formattedDuration, systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Date and tags
                HStack(spacing: 8) {
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    if !record.metadata.tags.isEmpty {
                        Text(record.metadata.tags.prefix(2).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Sync status indicator
            syncStatusIndicator
        }
        .padding(.vertical, 4)
    }

    // MARK: - Subviews

    private var thumbnailView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 56, height: 56)

            Image(systemName: "waveform")
                .font(.title2)
                .foregroundStyle(.accent)
        }
    }

    private var syncStatusIndicator: some View {
        Group {
            switch record.syncStatus {
            case .synced:
                Image(systemName: "checkmark.icloud")
                    .foregroundStyle(.green)
            case .pendingUpload:
                Image(systemName: "arrow.up.icloud")
                    .foregroundStyle(.orange)
            case .pendingDownload:
                Image(systemName: "arrow.down.icloud")
                    .foregroundStyle(.blue)
            case .conflict:
                Image(systemName: "exclamationmark.icloud")
                    .foregroundStyle(.red)
            case .localOnly:
                Image(systemName: "icloud.slash")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
    }

    // MARK: - Formatters

    private var formattedDuration: String {
        let minutes = Int(record.metadata.duration) / 60
        let seconds = Int(record.metadata.duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: record.metadata.recordedAt)
    }
}

#Preview {
    let sampleRecord = SoundscapeRecord(
        id: "rec_sample",
        userId: "user1",
        metadata: SoundscapeMetadata(
            title: "渋谷駅前の音風景",
            location: GeoLocation(latitude: 35.6580, longitude: 139.7016),
            recordedAt: Date(),
            duration: 185,
            tags: ["都市", "駅", "雑踏"],
            locationName: "渋谷区渋谷2丁目",
            equipment: Equipment(
                microphoneType: "内蔵マイク"
            )
        ),
        syncStatus: .synced
    )

    return List {
        RecordRowView(record: sampleRecord)
    }
    .listStyle(.plain)
}
