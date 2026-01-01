import SwiftUI

/// Recording control buttons
struct RecordingControlsView: View {
    let isRecording: Bool
    let isPaused: Bool
    let onRecord: () -> Void
    let onStop: () -> Void
    let onPause: () -> Void
    let onResume: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 40) {
            if isRecording {
                // Cancel button
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.gray)
                }

                // Stop button
                Button(action: onStop) {
                    ZStack {
                        Circle()
                            .fill(.red)
                            .frame(width: 80, height: 80)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: 28, height: 28)
                    }
                }

                // Pause/Resume button
                Button(action: isPaused ? onResume : onPause) {
                    Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(isPaused ? .green : .orange)
                }
            } else {
                // Record button
                Button(action: onRecord) {
                    ZStack {
                        Circle()
                            .stroke(.red, lineWidth: 4)
                            .frame(width: 80, height: 80)

                        Circle()
                            .fill(.red)
                            .frame(width: 64, height: 64)
                    }
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 60) {
        // Idle state
        RecordingControlsView(
            isRecording: false,
            isPaused: false,
            onRecord: {},
            onStop: {},
            onPause: {},
            onResume: {},
            onCancel: {}
        )

        // Recording state
        RecordingControlsView(
            isRecording: true,
            isPaused: false,
            onRecord: {},
            onStop: {},
            onPause: {},
            onResume: {},
            onCancel: {}
        )

        // Paused state
        RecordingControlsView(
            isRecording: true,
            isPaused: true,
            onRecord: {},
            onStop: {},
            onPause: {},
            onResume: {},
            onCancel: {}
        )
    }
    .padding()
}
