import SwiftUI
import SwiftData

/// Main evaluation input view
struct EvaluationInputView: View {
    let record: SoundscapeRecord
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var paqScores = PAQScores(
        pleasant: 3, chaotic: 3, vibrant: 3, uneventful: 3,
        calm: 3, annoying: 3, eventful: 3, monotonous: 3
    )
    @State private var soundSources = SoundSourcePerception(
        traffic: 0, other: 0, human: 0, natural: 0
    )
    @State private var overallLoudness = 5
    @State private var overallQuality = 3

    @State private var showingResult = false
    @State private var isSaving = false

    private var isoMetrics: ISOMetrics {
        ISOMetricsCalculator.calculate(from: paqScores)
    }

    private var isValid: Bool {
        paqScores.isValid && soundSources.isValid
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recording info header
                    recordInfoHeader

                    // PAQ Input
                    PAQInputView(paqScores: $paqScores)

                    // Sound source input
                    SoundSourceInputView(sources: $soundSources)

                    // Overall assessments
                    overallAssessmentSection

                    // Preview result
                    if isValid {
                        previewSection
                    }

                    // Submit button
                    submitButton
                }
                .padding()
            }
            .navigationTitle("主観評価")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingResult) {
                EvaluationResultView(
                    isoMetrics: isoMetrics,
                    sourceMetrics: SourceMetricsCalculator.calculate(from: soundSources)
                )
            }
        }
    }

    // MARK: - Record Info Header

    private var recordInfoHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(record.metadata.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    if let location = record.metadata.locationName {
                        Label(location, systemImage: "location")
                    }
                    Label(formatDuration(record.metadata.duration), systemImage: "clock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Overall Assessment

    private var overallAssessmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("総合評価")
                .font(.headline)

            VStack(spacing: 16) {
                // Loudness
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("音量感")
                            .font(.subheadline)
                        Spacer()
                        Text("\(overallLoudness)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 8) {
                        Text("静か")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Slider(value: Binding(
                            get: { Double(overallLoudness) },
                            set: { overallLoudness = Int($0) }
                        ), in: 1...10, step: 1)
                        .tint(.accentColor)

                        Text("うるさい")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Quality
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("総合的な音環境の質")
                            .font(.subheadline)
                        Spacer()
                        Text("\(overallQuality)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }

                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { rating in
                            Button {
                                overallQuality = rating
                            } label: {
                                Image(systemName: rating <= overallQuality ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundStyle(rating <= overallQuality ? .yellow : .secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("プレビュー")
                    .font(.headline)

                Spacer()

                Button {
                    showingResult = true
                } label: {
                    Label("詳細", systemImage: "arrow.up.right")
                        .font(.caption)
                }
            }

            CompactCircumplexView(isoMetrics: isoMetrics)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Submit Button

    private var submitButton: some View {
        Button {
            Task { @MainActor in
                await saveEvaluation()
            }
        } label: {
            HStack {
                if isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text("評価を保存")
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isValid ? Color.accentColor : Color.gray)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isValid || isSaving)
    }

    // MARK: - Actions

    @MainActor
    private func saveEvaluation() async {
        guard AuthManager.shared.userId != nil else { return }

        isSaving = true

        do {
            let dataStore = LocalDataStore(modelContext: modelContext)

            // Calculate metrics
            let sourceMetrics = SourceMetricsCalculator.calculate(from: soundSources)

            // Create evaluation
            let evaluation = SubjectiveEvaluation(
                id: SubjectiveEvaluation.generateId(),
                recordId: record.id,
                evaluatedAt: Date(),
                paqScores: paqScores,
                isoMetrics: isoMetrics,
                soundSources: soundSources,
                sourceMetrics: sourceMetrics,
                overallLoudness: overallLoudness,
                overallQuality: overallQuality
            )

            // Update record with evaluation
            var updatedRecord = record
            updatedRecord.evaluation = evaluation
            updatedRecord.updatedAt = Date()
            if updatedRecord.syncStatus == .synced {
                updatedRecord.syncStatus = .pendingUpload
            }

            try dataStore.updateRecord(updatedRecord)

            dismiss()
        } catch {
            print("Failed to save evaluation: \(error)")
            isSaving = false
        }
    }

    // MARK: - Helpers

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    EvaluationInputView(record: SoundscapeRecord(
        id: "rec_sample",
        userId: "user1",
        metadata: SoundscapeMetadata(
            title: "渋谷駅前の音風景",
            recordedAt: Date(),
            duration: 185,
            locationName: "渋谷区渋谷2丁目"
        )
    ))
    .modelContainer(for: LocalSoundscapeRecord.self, inMemory: true)
}
