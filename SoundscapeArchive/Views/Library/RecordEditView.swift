import SwiftUI
import SwiftData

/// Edit view for recording metadata
struct RecordEditView: View {
    let record: SoundscapeRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title: String
    @State private var description: String
    @State private var locationName: String
    @State private var tags: [String]
    @State private var newTag: String = ""
    @State private var isSaving = false

    init(record: SoundscapeRecord) {
        self.record = record
        _title = State(initialValue: record.metadata.title)
        _description = State(initialValue: record.metadata.description ?? "")
        _locationName = State(initialValue: record.metadata.locationName ?? "")
        _tags = State(initialValue: record.metadata.tags)
    }

    var body: some View {
        Form {
            // Basic info
            Section("基本情報") {
                TextField("タイトル", text: $title)

                TextField("場所", text: $locationName)

                VStack(alignment: .leading) {
                    Text("メモ")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
            }

            // Tags
            Section("タグ") {
                // Existing tags
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                            Button {
                                tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                    }
                }

                // Add new tag
                HStack {
                    TextField("新しいタグ", text: $newTag)
                        .textInputAutocapitalization(.never)
                    Button("追加") {
                        addTag()
                    }
                    .disabled(newTag.isEmpty)
                }
            }

            // Suggested tags
            Section("おすすめタグ") {
                let suggestions = suggestedTags.filter { !tags.contains($0) }
                if suggestions.isEmpty {
                    Text("すべてのおすすめタグを追加済みです")
                        .foregroundStyle(.secondary)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(suggestions, id: \.self) { tag in
                            Button {
                                tags.append(tag)
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text(tag)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
            }

            // Recording info (read-only)
            Section("録音情報") {
                HStack {
                    Text("録音日時")
                    Spacer()
                    Text(formatDateTime(record.metadata.recordedAt))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("長さ")
                    Spacer()
                    Text(formatDuration(record.metadata.duration))
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("機器")
                    Spacer()
                    Text(record.metadata.equipment.deviceModel)
                        .foregroundStyle(.secondary)
                }

                if let location = record.metadata.location {
                    HStack {
                        Text("座標")
                        Spacer()
                        Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .navigationTitle("録音を編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    save()
                }
                .disabled(title.isEmpty || isSaving)
            }
        }
    }

    // MARK: - Suggested Tags

    private var suggestedTags: [String] {
        [
            "都市", "自然", "公園", "駅", "街路",
            "水辺", "森林", "住宅街", "商業地",
            "朝", "昼", "夕方", "夜",
            "静か", "賑やか", "癒し"
        ]
    }

    // MARK: - Actions

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }

    private func save() {
        isSaving = true

        Task {
            do {
                let dataStore = LocalDataStore(modelContext: modelContext)

                // Create updated metadata
                let updatedMetadata = SoundscapeMetadata(
                    title: title,
                    description: description.isEmpty ? nil : description,
                    recordedAt: record.metadata.recordedAt,
                    duration: record.metadata.duration,
                    sampleRate: record.metadata.sampleRate,
                    channels: record.metadata.channels,
                    bitDepth: record.metadata.bitDepth,
                    location: record.metadata.location,
                    locationName: locationName.isEmpty ? nil : locationName,
                    equipment: record.metadata.equipment,
                    tags: tags
                )

                // Create updated record
                var updatedRecord = record
                updatedRecord.metadata = updatedMetadata
                updatedRecord.updatedAt = Date()

                // Mark for re-sync if previously synced
                if updatedRecord.syncStatus == .synced {
                    updatedRecord.syncStatus = .pendingUpload
                }

                try dataStore.updateRecord(updatedRecord)

                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to save: \(error)")
                isSaving = false
            }
        }
    }

    // MARK: - Formatters

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d分%02d秒", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        RecordEditView(record: SoundscapeRecord(
            id: "rec_sample",
            userId: "user1",
            metadata: SoundscapeMetadata(
                title: "渋谷駅前の音風景",
                description: "朝のラッシュ時間帯の録音",
                location: GeoLocation(latitude: 35.6580, longitude: 139.7016),
                recordedAt: Date(),
                duration: 185,
                tags: ["都市", "駅"],
                locationName: "渋谷区渋谷2丁目",
                equipment: Equipment(
                    microphone: "内蔵マイク"
                )
            ),
            syncStatus: .synced
        ))
    }
    .modelContainer(for: LocalSoundscapeRecord.self, inMemory: true)
}
