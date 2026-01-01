import SwiftUI
import SwiftData

/// Detail view for a single recording
struct RecordDetailView: View {
    let record: SoundscapeRecord
    @Environment(\.modelContext) private var modelContext
    @State private var audioPlayer = AudioPlayer()
    @State private var showingEvaluationSheet = false
    @State private var showingEditSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Playback section
                playbackSection

                Divider()

                // Metadata section
                metadataSection

                Divider()

                // Evaluation section
                evaluationSection

                // Analysis section (if available)
                if record.acousticAnalysis != nil {
                    Divider()
                    analysisSection
                }
            }
            .padding()
        }
        .navigationTitle(record.metadata.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("編集")
                }
            }
        }
        .onAppear {
            loadAudio()
        }
        .onDisappear {
            audioPlayer.stop()
        }
        .sheet(isPresented: $showingEvaluationSheet) {
            EvaluationInputView(record: record)
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                RecordEditView(record: record)
            }
        }
    }

    // MARK: - Load Audio

    private func loadAudio() {
        do {
            let dataStore = LocalDataStore(modelContext: modelContext)
            let audioPath = try dataStore.getAudioPath(recordId: record.id)
            let audioURL = URL(fileURLWithPath: audioPath)
            try audioPlayer.load(url: audioURL)
        } catch {
            print("Failed to load audio: \(error)")
        }
    }

    // MARK: - Playback Section

    private var playbackSection: some View {
        VStack(spacing: 16) {
            // Waveform visualization placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(height: 120)

                // Simple waveform representation
                HStack(spacing: 2) {
                    ForEach(0..<50, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor.opacity(
                                Double(i) / 50.0 < audioPlayer.progress ? 1.0 : 0.3
                            ))
                            .frame(width: 4, height: CGFloat.random(in: 20...80))
                    }
                }
                .padding(.horizontal)
            }

            // Time display
            HStack {
                Text(formatTime(audioPlayer.currentTime))
                    .font(.caption)
                    .monospacedDigit()
                Spacer()
                Text(formatTime(audioPlayer.duration))
                    .font(.caption)
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)

            // Progress slider
            Slider(value: Binding(
                get: { audioPlayer.progress },
                set: { audioPlayer.seek(to: $0) }
            ))
            .tint(.accentColor)

            // Playback controls
            HStack(spacing: 32) {
                Button {
                    audioPlayer.skip(seconds: -15)
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }

                Button {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64))
                }

                Button {
                    audioPlayer.skip(seconds: 15)
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
            }
            .foregroundStyle(.accent)
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("詳細")
                .font(.headline)

            // Info grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                DetailItem(
                    icon: "calendar",
                    label: "録音日時",
                    value: formatDateTime(record.metadata.recordedAt)
                )

                DetailItem(
                    icon: "clock",
                    label: "長さ",
                    value: formatDuration(record.metadata.duration)
                )

                if let location = record.metadata.locationName {
                    DetailItem(
                        icon: "location",
                        label: "場所",
                        value: location
                    )
                }

                DetailItem(
                    icon: "iphone",
                    label: "機器",
                    value: record.metadata.equipment.deviceModel
                )
            }

            // Description
            if let description = record.metadata.description {
                VStack(alignment: .leading, spacing: 4) {
                    Text("メモ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(description)
                        .font(.body)
                }
            }

            // Tags
            if !record.metadata.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("タグ")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    DetailFlowLayout(spacing: 8) {
                        ForEach(record.metadata.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Evaluation Section

    private var evaluationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("主観評価")
                    .font(.headline)
                Spacer()
                if record.evaluation == nil {
                    Button {
                        showingEvaluationSheet = true
                    } label: {
                        Label("評価を追加", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                }
            }

            if let evaluation = record.evaluation {
                // Show evaluation summary
                EvaluationSummaryView(evaluation: evaluation)
            } else {
                // No evaluation yet
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("まだ評価がありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("PAQ評価を追加して音風景を分析しましょう")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
    }

    // MARK: - Analysis Section

    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("音響分析")
                .font(.headline)

            if let analysis = record.acousticAnalysis {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    if let laeq = analysis.laeq {
                        DetailItem(
                            icon: "speaker.wave.2",
                            label: "LAeq",
                            value: String(format: "%.1f dB", laeq)
                        )
                    }

                    if let lamax = analysis.lamax {
                        DetailItem(
                            icon: "speaker.wave.3",
                            label: "LAmax",
                            value: String(format: "%.1f dB", lamax)
                        )
                    }

                    if let lamin = analysis.lamin {
                        DetailItem(
                            icon: "speaker.wave.1",
                            label: "LAmin",
                            value: String(format: "%.1f dB", lamin)
                        )
                    }

                    if let la10 = analysis.la10 {
                        DetailItem(
                            icon: "chart.bar",
                            label: "LA10",
                            value: String(format: "%.1f dB", la10)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Formatters

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

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

// MARK: - Detail Item

private struct DetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
            }

            Spacer()
        }
    }
}

// MARK: - Flow Layout

private struct DetailFlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var positions: [CGPoint] = []
        var size: CGSize = .zero

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
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
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Evaluation Summary View

struct EvaluationSummaryView: View {
    let evaluation: SubjectiveEvaluation

    var body: some View {
        VStack(spacing: 16) {
            // Circumplex chart
            CompactCircumplexView(isoMetrics: evaluation.isoMetrics)

            // Overall ratings
            HStack(spacing: 24) {
                VStack {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { i in
                            Image(systemName: i <= evaluation.overallQuality ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundStyle(i <= evaluation.overallQuality ? .yellow : .secondary)
                        }
                    }
                    Text("総合評価")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack {
                    Text("\(evaluation.overallLoudness)")
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("音量感")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        RecordDetailView(record: SoundscapeRecord(
            id: "rec_sample",
            userId: "user1",
            metadata: SoundscapeMetadata(
                title: "渋谷駅前の音風景",
                description: "朝のラッシュ時間帯の録音。人の往来が多く、電車の音も聞こえる。",
                location: GeoLocation(latitude: 35.6580, longitude: 139.7016),
                recordedAt: Date(),
                duration: 185,
                tags: ["都市", "駅", "雑踏", "朝"],
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
