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
        if let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "wav"),
           let file = try? AVAudioFile(forReading: url) {
            let format = file.processingFormat
            let frameCount = AVAudioFrameCount(file.length)
            if let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                try? file.read(into: buf)
                buffer = buf
            }
        } else {
            buffer = synthesizeClick(sampleRate: 44100)
        }
    }

    private func synthesizeClick(sampleRate: Double) -> AVAudioPCMBuffer? {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
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
        if !engine.isRunning { try? engine.start() }
        nextBeatTime = AVAudioTime(hostTime: mach_absolute_time())
        scheduleBeat()
    }

    private func scheduleBeat() {
        guard isPlaying, let buf = buffer, let beatTime = nextBeatTime else { return }
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
