import AVFoundation

@Observable
@MainActor
final class MetronomeService {
    private(set) var bpm: Int = 180
    var soundType: SoundType = .tap
    var volume: Float = 0.7
    private(set) var isPlaying: Bool = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var nextBeatTime: AVAudioTime?
    private var buffer: AVAudioPCMBuffer?

    init() {
        setupEngine()
        loadBuffer()
    }

    static func beatInterval(bpm: Int) -> Double {
        60.0 / Double(bpm)
    }

    private func setupEngine() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try? engine.start()
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func loadBuffer() {
        // Use the engine's output sample rate so buffer format always matches
        let engineSampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
        let sampleRate = engineSampleRate > 0 ? engineSampleRate : 44100

        if let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "wav"),
           let file = try? AVAudioFile(forReading: url) {
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)
            if let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
               buf.frameCapacity > 0 {
                try? file.read(into: buf)
                buffer = buf
            } else {
                buffer = synthesizeClick(sampleRate: sampleRate)
            }
        } else {
            buffer = synthesizeClick(sampleRate: sampleRate)
        }
    }

    private func synthesizeClick(sampleRate: Double) -> AVAudioPCMBuffer? {
        // Must match engine output format — use same sample rate and channel count
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let channels = outputFormat.channelCount > 0 ? outputFormat.channelCount : 1
        let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : sampleRate
        guard let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: channels) else { return nil }
        // 40ms click — enough for a wood block transient
        let frameCount: AVAudioFrameCount = AVAudioFrameCount(sampleRate * 0.04)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buf.frameLength = frameCount
        let ch = buf.floatChannelData![0]

        // Wood block: two detuned sine waves (800 Hz + 1200 Hz) + very fast exponential decay
        // Sounds warmer and less piercing than a single sine
        let isTap = soundType == .tap
        let freq1: Double = isTap ? 1800 : 800
        let freq2: Double = isTap ? 2400 : 1200
        let decay: Double = isTap ? 150  : 80    // tap decays slower → softer

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * decay)
            let signal = sin(2 * .pi * freq1 * t) * 0.6
                       + sin(2 * .pi * freq2 * t) * 0.4
            ch[i] = Float(signal * envelope * Double(volume))
        }
        return buf
    }

    func start() {
        isPlaying = true
        if !engine.isRunning {
            do { try engine.start() } catch { isPlaying = false; return }
        }
        nextBeatTime = AVAudioTime(hostTime: mach_absolute_time())
        scheduleBeat()
    }

    private func scheduleBeat() {
        guard isPlaying,
              let buf = buffer,
              buf.frameLength > 0,
              let beatTime = nextBeatTime,
              engine.isRunning else { return }
        player.scheduleBuffer(buf, at: beatTime, options: []) { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.isPlaying else { return }
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
        player.stop()
        nextBeatTime = nil
    }

    func pause() {
        isPlaying = false
        player.pause()
    }

    func resume() {
        isPlaying = true
        player.play()
    }

    func updateBPM(_ newBPM: Int) {
        bpm = newBPM
    }

    func updateSoundType(_ type: SoundType) {
        soundType = type
        loadBuffer()
    }
}
