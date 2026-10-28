import Foundation
import AVFoundation

public final class AudioManager: @unchecked Sendable {
    public static let shared = AudioManager()

    private let engine = AVAudioEngine()
    private let sfxMixer = AVAudioMixerNode()
    private let bgmMixer = AVAudioMixerNode()

    private var sfxPlayers: [AVAudioPlayerNode] = []
    private var bgmPlayer = AVAudioPlayerNode()
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]

    private var audioFormat: AVAudioFormat?

    public var isMuted: Bool = false
    public var sfxVolume: Float = 1.0 {
        didSet { sfxMixer.outputVolume = isMuted ? 0 : sfxVolume }
    }
    public var bgmVolume: Float = 0.8 {
        didSet { bgmMixer.outputVolume = isMuted ? 0 : bgmVolume }
    }

    public init() {
        setupEngine()
    }

    private func setupEngine() {
        engine.attach(sfxMixer)
        engine.attach(bgmMixer)
        engine.attach(bgmPlayer)

        let format = engine.outputNode.outputFormat(forBus: 0)
        self.audioFormat = format

        engine.connect(sfxMixer, to: engine.mainMixerNode, format: format)
        engine.connect(bgmMixer, to: engine.mainMixerNode, format: format)
        engine.connect(bgmPlayer, to: bgmMixer, format: format)

        // SFX player pool (Polyphony - to play multiple concurrent sounds)
        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: sfxMixer, format: format)
            sfxPlayers.append(player)
        }

        do {
            try engine.start()
        } catch {
            print("⚠️ [Astorka Audio] Failed to start AVAudioEngine: \(error)")
        }
    }

    /// Pre-loads an audio file into a PCM buffer
    public func loadSound(named name: String, from fileURL: URL) {
        do {
            let file = try AVAudioFile(forReading: fileURL)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else { return }
            try file.read(into: buffer)
            audioBuffers[name] = buffer
        } catch {
            print("⚠️ [Astorka Audio] Failed to load sound: \(name), \(error)")
        }
    }

    /// Plays a sound (from buffer if loaded, otherwise procedurally synthesized retro SFX)
    public func playSound(_ name: String, volume: Float = 1.0) {
        guard !isMuted else { return }

        // Play from audio buffer if available
        if let buffer = audioBuffers[name] {
            if let freePlayer = sfxPlayers.first(where: { !$0.isPlaying }) ?? sfxPlayers.first {
                freePlayer.volume = volume
                freePlayer.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                if !freePlayer.isPlaying { freePlayer.play() }
                return
            }
        }

        // Fallback to procedurally synthesized retro sound if file not found
        playProceduralSFX(type: name, volume: volume)
    }

    /// Built-in synthesizer: Generates 8-bit / arcade sounds without external files
    private func playProceduralSFX(type: String, volume: Float) {
        guard let format = self.audioFormat else { return }
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44100.0
        let duration: Double
        let baseFreq: Double

        switch type.lowercased() {
        case "click", "select", "tap":
            duration = 0.04; baseFreq = 800.0
        case "coin", "gold", "pickup":
            duration = 0.12; baseFreq = 987.77 // B5
        case "hit", "damage", "slash":
            duration = 0.15; baseFreq = 160.0
        case "victory", "win":
            duration = 0.35; baseFreq = 523.25 // C5
        default:
            duration = 0.08; baseFreq = 440.0
        }

        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        let channelCount = Int(format.channelCount)
        for ch in 0..<channelCount {
            guard let channelData = buffer.floatChannelData?[ch] else { continue }
            for i in 0..<Int(frameCount) {
                let t = Double(i) / sampleRate
                let envelope = 1.0 - (t / duration)
                let freq = baseFreq * (1.0 + (type.lowercased() == "coin" ? t * 2.0 : 0.0))
                let sample = Float(sin(2.0 * .pi * freq * t) * envelope) * volume * 0.25
                channelData[i] = sample
            }
        }

        if let player = sfxPlayers.first(where: { !$0.isPlaying }) ?? sfxPlayers.first {
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            if !player.isPlaying { player.play() }
        }
    }
}
