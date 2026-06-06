import AVFoundation

@Observable
@MainActor
final class MetronomeService {
    private(set) var bpm: Int = 180
    var soundType: SoundType = .wood
    var volume: Float = 0.7 {
        didSet { engine.mainMixerNode.outputVolume = volume }
    }
    private(set) var isPlaying: Bool = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var strongBuffer: AVAudioPCMBuffer?  // beat 1 — accent
    private var weakBuffer: AVAudioPCMBuffer?    // beat 2 — soft
    private var nextBeatTime: AVAudioTime?
    private var beatCount: Int = 0               // alternates 0/1

    init() {
        setupEngine()
        loadBuffers()
    }

    static func beatInterval(bpm: Int) -> Double { 60.0 / Double(bpm) }

    private func setupEngine() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = volume
        try? engine.start()
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func loadBuffers() {
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100
        strongBuffer = synthesize(sampleRate: rate, high: true)
        weakBuffer   = synthesize(sampleRate: rate, high: false)
    }

    // MARK: - Synthesis

    private func synthesize(sampleRate: Double, high: Bool) -> AVAudioPCMBuffer? {
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let channels = outputFormat.channelCount > 0 ? outputFormat.channelCount : 1
        let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : sampleRate
        guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: channels) else { return nil }

        let durationMs: Double = soundType == .bell ? 80 : 40
        let frameCount = AVAudioFrameCount(rate * durationMs / 1000)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount

        for ch in 0..<Int(channels) {
            let ptr = buf.floatChannelData![ch]
            for i in 0..<Int(frameCount) {
                let t = Double(i) / rate
                ptr[i] = Float(sample(t: t, rate: rate, high: high))
            }
        }
        return buf
    }

    // high = beat 1 (higher pitch), low = beat 2 (lower pitch)
    private func sample(t: Double, rate: Double, high: Bool) -> Double {
        let pitchMult: Double = high ? 1.0 : 0.6  // beat 2 is ~a fifth lower

        switch soundType {
        case .tap:
            let env = exp(-t * 200)
            let f1 = 2200 * pitchMult, f2 = 3100 * pitchMult
            return (sin(2 * .pi * f1 * t) * 0.6 + sin(2 * .pi * f2 * t) * 0.4) * env

        case .bell:
            let env = exp(-t * 25)
            let env2 = exp(-t * 60)
            let f1 = 880 * pitchMult, f2 = 2640 * pitchMult
            return sin(2 * .pi * f1 * t) * 0.7 * env + sin(2 * .pi * f2 * t) * 0.3 * env2

        case .drum:
            let env = exp(-t * 80)
            let noise = Double.random(in: -1...1)
            let f1 = 80 * pitchMult
            return (sin(2 * .pi * f1 * t) * 0.8 + noise * 0.2) * env

        case .wood:
            let env = exp(-t * 100)
            let f1 = 800 * pitchMult, f2 = 1200 * pitchMult
            return (sin(2 * .pi * f1 * t) * 0.6 + sin(2 * .pi * f2 * t) * 0.4) * env
        }
    }

    // MARK: - Playback

    func start() {
        isPlaying = true
        beatCount = 0
        if !engine.isRunning {
            do { try engine.start() } catch { isPlaying = false; return }
        }
        nextBeatTime = AVAudioTime(hostTime: mach_absolute_time())
        scheduleBeat()
    }

    private func scheduleBeat() {
        guard isPlaying,
              let beatTime = nextBeatTime,
              engine.isRunning else { return }

        let buf = (beatCount % 2 == 0) ? strongBuffer : weakBuffer
        guard let buf, buf.frameLength > 0 else { return }

        player.scheduleBuffer(buf, at: beatTime, options: []) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.isPlaying else { return }
                self.beatCount += 1
                self.scheduleBeat()
            }
        }
        if !player.isPlaying { player.play() }

        var timebaseInfo = mach_timebase_info_data_t()
        mach_timebase_info(&timebaseInfo)
        let nsPerTick = Double(timebaseInfo.numer) / Double(timebaseInfo.denom)
        let nsPerBeat = Self.beatInterval(bpm: bpm) * 1_000_000_000
        let ticksPerBeat = UInt64(nsPerBeat / nsPerTick)
        nextBeatTime = AVAudioTime(hostTime: beatTime.hostTime + ticksPerBeat)
    }

    func stop() {
        isPlaying = false
        beatCount = 0
        player.stop()
        nextBeatTime = nil
    }

    func pause() {
        isPlaying = false
        player.stop()  // clears the buffer queue to prevent overlap on resume
        nextBeatTime = nil
    }

    func resume() {
        isPlaying = true
        if !engine.isRunning {
            try? engine.start()
        }
        // Re-schedule from now so no gap or overlap
        nextBeatTime = AVAudioTime(hostTime: mach_absolute_time())
        scheduleBeat()
    }

    func updateBPM(_ newBPM: Int) { bpm = newBPM }

    func updateSoundType(_ type: SoundType) {
        soundType = type
        loadBuffers()
    }
}
