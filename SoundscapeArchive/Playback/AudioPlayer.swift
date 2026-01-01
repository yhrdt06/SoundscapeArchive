import Foundation
import AVFoundation
import Combine

/// Audio player for playback of recorded soundscapes
@MainActor
@Observable
final class AudioPlayer: NSObject {
    // MARK: - State

    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isLoaded = false
    private(set) var error: Error?

    // MARK: - Private

    private var player: AVAudioPlayer?
    private var displayLink: CADisplayLink?
    private var currentURL: URL?

    // MARK: - Load

    /// Load audio file from URL
    func load(url: URL) throws {
        // Stop current playback
        stop()

        // Load new file
        player = try AVAudioPlayer(contentsOf: url)
        player?.delegate = self
        player?.prepareToPlay()

        currentURL = url
        duration = player?.duration ?? 0
        currentTime = 0
        isLoaded = true
        error = nil
    }

    /// Load audio file from local path
    func load(path: String) throws {
        let url = URL(fileURLWithPath: path)
        try load(url: url)
    }

    // MARK: - Playback Controls

    /// Start playback
    func play() {
        guard isLoaded, let player = player else { return }

        // Configure audio session
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            self.error = error
            return
        }

        player.play()
        isPlaying = true
        startProgressUpdate()
    }

    /// Pause playback
    func pause() {
        player?.pause()
        isPlaying = false
        stopProgressUpdate()
    }

    /// Stop playback
    func stop() {
        player?.stop()
        player?.currentTime = 0
        currentTime = 0
        isPlaying = false
        stopProgressUpdate()
    }

    /// Toggle play/pause
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    /// Seek to specific time
    func seek(to time: TimeInterval) {
        let clampedTime = max(0, min(time, duration))
        player?.currentTime = clampedTime
        currentTime = clampedTime
    }

    /// Seek by percentage (0.0 to 1.0)
    func seekToProgress(_ progress: Double) {
        let time = progress * duration
        seek(to: time)
    }

    /// Skip forward by seconds
    func skipForward(_ seconds: TimeInterval = 10) {
        seek(to: currentTime + seconds)
    }

    /// Skip backward by seconds
    func skipBackward(_ seconds: TimeInterval = 10) {
        seek(to: currentTime - seconds)
    }

    /// Skip by seconds (positive or negative)
    func skip(seconds: TimeInterval) {
        if seconds >= 0 {
            skipForward(seconds)
        } else {
            skipBackward(-seconds)
        }
    }

    // MARK: - Progress

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var remainingTime: TimeInterval {
        duration - currentTime
    }

    // MARK: - Formatted Time

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    var formattedRemainingTime: String {
        "-" + formatTime(remainingTime)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let totalSeconds = Int(time)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Private Methods

    private func startProgressUpdate() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateProgress))
        displayLink?.add(to: .main, forMode: .common)
    }

    private func stopProgressUpdate() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateProgress() {
        currentTime = player?.currentTime ?? 0
    }

    // MARK: - Cleanup

    func cleanup() {
        stop()
        player = nil
        currentURL = nil
        isLoaded = false
        duration = 0
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = 0
            self.stopProgressUpdate()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.error = error
            self.isPlaying = false
            self.stopProgressUpdate()
        }
    }
}
