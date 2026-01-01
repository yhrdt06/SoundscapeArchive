import SwiftUI
import SwiftData

/// Main recording screen
struct RecordingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RecordingViewModel?
    @State private var showMetadataEdit = false
    @State private var completedRecord: SoundscapeRecord?

    var body: some View {
        NavigationStack {
            if let viewModel = viewModel {
                RecordingContentView(
                    viewModel: viewModel,
                    modelContext: modelContext,
                    showMetadataEdit: $showMetadataEdit,
                    completedRecord: $completedRecord
                )
            } else {
                ProgressView("準備中...")
                    .task {
                        await MainActor.run {
                            viewModel = RecordingViewModel()
                        }
                    }
            }
        }
    }
}

/// Inner content view that uses the ViewModel
@MainActor
private struct RecordingContentView: View {
    var viewModel: RecordingViewModel
    let modelContext: ModelContext
    @Binding var showMetadataEdit: Bool
    @Binding var completedRecord: SoundscapeRecord?

    var body: some View {
        VStack(spacing: 0) {
            // Status area
            statusArea
                .frame(height: 100)

            Spacer()

            // Level meter
            VUMeterView(level: viewModel.currentLevel, peak: viewModel.peakLevel)
                .frame(height: 200)
                .padding(.horizontal, 40)

            Spacer()

            // Waveform preview
            if !viewModel.waveformSamples.isEmpty {
                WaveformPreviewView(samples: viewModel.waveformSamples)
                    .frame(height: 80)
                    .padding(.horizontal)
            }

            Spacer()

            // Duration display
            Text(viewModel.formattedDuration)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundStyle(viewModel.isRecording ? .primary : .secondary)

            Spacer()

            // Recording controls
            RecordingControlsView(
                isRecording: viewModel.isRecording,
                isPaused: viewModel.isPaused,
                onRecord: startRecording,
                onStop: stopRecording,
                onPause: viewModel.pauseRecording,
                onResume: viewModel.resumeRecording,
                onCancel: viewModel.cancelRecording
            )
            .padding(.bottom, 40)
        }
        .navigationTitle("録音")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                locationStatusIcon
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            Task {
                await viewModel.requestPermissions()
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { viewModel.showError },
            set: { _ in viewModel.resetState() }
        )) {
            Button("OK") {
                viewModel.resetState()
            }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "不明なエラー")
        }
        .sheet(isPresented: $showMetadataEdit) {
            if let record = completedRecord {
                RecordingMetadataEditView(record: record) { _ in
                    // Save updated record
                    showMetadataEdit = false
                    completedRecord = nil
                    viewModel.resetState()
                }
            }
        }
        .onChange(of: viewModel.recordingState) { _, newState in
            if case .completed(let record) = newState {
                completedRecord = record
                showMetadataEdit = true
            }
        }
    }

    // MARK: - Status Area

    private var statusArea: some View {
        VStack(spacing: 8) {
            // Recording status
            HStack(spacing: 8) {
                if viewModel.isRecording {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .opacity(viewModel.isPaused ? 0.5 : 1.0)

                    Text(viewModel.isPaused ? "一時停止中" : "録音中")
                        .font(.headline)
                        .foregroundStyle(viewModel.isPaused ? Color.secondary : Color.red)
                } else {
                    Text("録音準備完了")
                        .font(.headline)
                        .foregroundStyle(Color.secondary)
                }
            }

            // Location info
            if let location = viewModel.currentLocation {
                Text(String(format: "%.4f, %.4f", location.latitude, location.longitude))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Permission warnings
            if !viewModel.hasMicrophonePermission {
                Label("マイクへのアクセスを許可してください", systemImage: "mic.slash")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
    }

    // MARK: - Location Status Icon

    private var locationStatusIcon: some View {
        Group {
            switch viewModel.locationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                if viewModel.currentLocation != nil {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "location")
                        .foregroundStyle(.secondary)
                }
            case .denied, .restricted:
                Image(systemName: "location.slash")
                    .foregroundStyle(.red)
            default:
                Image(systemName: "location")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        Task {
            await viewModel.startRecording()
        }
    }

    private func stopRecording() {
        Task {
            await viewModel.stopRecording()
        }
    }
}

#Preview {
    RecordingView()
        .modelContainer(for: [LocalSoundscapeRecord.self, LocalEvaluation.self])
}
