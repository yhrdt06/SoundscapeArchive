import SwiftUI

/// Metadata editing view after recording
struct RecordingMetadataEditView: View {
    @Environment(\.dismiss) private var dismiss

    let record: SoundscapeRecord
    let onSave: (SoundscapeRecord) -> Void

    @State private var title: String
    @State private var description: String
    @State private var locationName: String
    @State private var tags: [String]
    @State private var newTag: String = ""
    @State private var weather: String
    @State private var temperature: String
    @State private var notes: String

    init(record: SoundscapeRecord, onSave: @escaping (SoundscapeRecord) -> Void) {
        self.record = record
        self.onSave = onSave

        _title = State(initialValue: record.metadata.title)
        _description = State(initialValue: record.metadata.description ?? "")
        _locationName = State(initialValue: record.metadata.locationName ?? "")
        _tags = State(initialValue: record.metadata.tags)
        _weather = State(initialValue: record.metadata.weather ?? "")
        _temperature = State(initialValue: record.metadata.temperature.map { String($0) } ?? "")
        _notes = State(initialValue: record.metadata.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Basic info
                Section("基本情報") {
                    TextField("タイトル", text: $title)

                    TextField("説明", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Recording info (read-only)
                Section("録音情報") {
                    LabeledContent("時間", value: record.metadata.formattedDuration)
                    LabeledContent("サイズ", value: record.metadata.formattedFileSize)
                    LabeledContent("形式", value: "\(record.metadata.sampleRate)Hz / \(record.metadata.bitDepth)bit")

                    if record.metadata.location.isValid {
                        LabeledContent("座標") {
                            Text(String(format: "%.4f, %.4f",
                                       record.metadata.location.latitude,
                                       record.metadata.location.longitude))
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                // Location
                Section("場所") {
                    TextField("場所の名前", text: $locationName)
                }

                // Tags
                Section("タグ") {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagView(tag: tag) {
                                tags.removeAll { $0 == tag }
                            }
                        }
                    }

                    HStack {
                        TextField("新しいタグ", text: $newTag)
                            .textInputAutocapitalization(.never)

                        Button("追加") {
                            addTag()
                        }
                        .disabled(newTag.isEmpty)
                    }
                }

                // Weather
                Section("天候") {
                    Picker("天気", selection: $weather) {
                        Text("未選択").tag("")
                        Text("晴れ").tag("晴れ")
                        Text("曇り").tag("曇り")
                        Text("雨").tag("雨")
                        Text("雪").tag("雪")
                        Text("風強").tag("風強")
                    }

                    HStack {
                        Text("気温")
                        Spacer()
                        TextField("", text: $temperature)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                        Text("°C")
                    }
                }

                // Notes
                Section("メモ") {
                    TextField("メモ", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }

                // Waveform preview
                if let waveform = record.waveformPreview, !waveform.isEmpty {
                    Section("波形") {
                        WaveformPlayerView(samples: waveform, progress: 0)
                            .frame(height: 60)
                    }
                }
            }
            .navigationTitle("録音を保存")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveRecord()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            tags.append(trimmed)
            newTag = ""
        }
    }

    private func saveRecord() {
        var updatedMetadata = record.metadata
        updatedMetadata.title = title
        updatedMetadata.description = description.isEmpty ? nil : description
        updatedMetadata.locationName = locationName.isEmpty ? nil : locationName
        updatedMetadata.tags = tags
        updatedMetadata.weather = weather.isEmpty ? nil : weather
        updatedMetadata.temperature = Double(temperature)
        updatedMetadata.notes = notes.isEmpty ? nil : notes

        var updatedRecord = record
        updatedRecord.metadata = updatedMetadata
        updatedRecord.updatedAt = Date()

        onSave(updatedRecord)
    }
}

// MARK: - Tag View

struct TagView: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .foregroundStyle(.blue)
        .cornerRadius(16)
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)

        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var frames: [CGRect] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), frames)
    }
}

#Preview {
    let metadata = SoundscapeMetadata(
        title: "テスト録音",
        location: GeoLocation(latitude: 35.6812, longitude: 139.7671),
        recordedAt: Date(),
        duration: 125.5,
        fileSize: 5_500_000
    )

    let record = SoundscapeRecord(
        userId: "preview-user",
        metadata: metadata,
        waveformPreview: (0..<50).map { _ in Double.random(in: 0.1...1.0) }
    )

    return RecordingMetadataEditView(record: record) { _ in }
}
