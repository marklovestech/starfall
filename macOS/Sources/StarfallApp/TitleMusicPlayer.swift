import AVFoundation
import Observation
import StarfallCore

@MainActor @Observable
final class TitleMusicPlayer {
    @ObservationIgnored private var engine: AVAudioEngine?
    @ObservationIgnored private var player: AVAudioPlayerNode?
    private var playbackID: UUID?

    var isPlaying: Bool { playbackID != nil }

    func play() {
        guard !isPlaying,
              let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1),
              let buffer = Self.render(format: format) else { return }
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do { try engine.start() }
        catch { return }

        let id = UUID()
        playbackID = id
        self.engine = engine
        self.player = player
        player.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { @Sendable [weak self] _ in
            Task { @MainActor in
                guard let self, self.playbackID == id else { return }
                self.stop()
            }
        }
        player.play()
    }

    func stop() {
        playbackID = nil
        player?.stop()
        engine?.stop()
        player = nil
        engine = nil
    }

    private static func render(format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let notes = TitleMusic.notes
        let framesPerMillisecond = Int(format.sampleRate) / 1_000
        let counts = notes.map { $0.durationMilliseconds * framesPerMillisecond }
        let frameCount = AVAudioFrameCount(counts.reduce(0, +))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = frameCount

        let rampFrames = 2 * framesPerMillisecond
        var offset = 0
        for (note, count) in zip(notes, counts) {
            let cyclesPerFrame = Double(note.frequencyHz) / format.sampleRate
            for frame in 0..<count {
                let cycles = Double(frame) * cyclesPerFrame
                let square: Float = cycles - cycles.rounded(.down) < 0.5 ? 0.1 : -0.1
                let gain = Float(min(frame, count - 1 - frame, rampFrames)) / Float(rampFrames)
                samples[offset + frame] = square * gain
            }
            offset += count
        }
        return buffer
    }
}
