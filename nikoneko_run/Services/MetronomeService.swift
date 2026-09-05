import AVFoundation

@Observable
@MainActor
final class MetronomeService {
    /// AirPlay and Bluetooth A2DP are supported automatically by `.playback`.
    /// Supplying their category options can make `setCategory` fail with
    /// `kAudio_ParamError` (-50) on some routes and Simulator runtimes.
    static let audioSessionCategoryOptions: AVAudioSession.CategoryOptions = [
        .mixWithOthers,
    ]

    private(set) var bpm: Int = 180
    var soundType: SoundType = .wood
    var volume: Float = 0.7 {
        didSet {
            guard isPrepared else { return }
            engine.mainMixerNode.outputVolume = volume
        }
    }
    private(set) var isPlaying: Bool = false
    private(set) var lastPlaybackError: String?

    @ObservationIgnored private lazy var engine = AVAudioEngine()
    @ObservationIgnored private lazy var player = AVAudioPlayerNode()
    private var loopBuffer: AVAudioPCMBuffer?
    private var isPrepared = false
    private var isStartingPlayback = false
    private var interruptionObserver: NSObjectProtocol?
    private var configChangeObserver: NSObjectProtocol?

    /// User intent is kept separately so an interruption or route change can recover playback.
    private var playbackRequested = false
    private var wasPlayingBeforeInterruption = false

    init() {}

    private func prepareIfNeeded() {
        guard !isPrepared else { return }
        isPrepared = true
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        engine.mainMixerNode.outputVolume = volume
        setupInterruptionHandler()
        setupConfigChangeHandler()
    }

    private func activateAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playback,
            mode: .default,
            options: Self.audioSessionCategoryOptions
        )
        try session.setActive(true)
    }

    private func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(
                false,
                options: .notifyOthersOnDeactivation
            )
        } catch {
            // Deactivation failure is non-fatal; playback is already stopped locally.
            print("⚠️ [Metronome] Could not deactivate audio session: \(error)")
        }
    }

    private func setupInterruptionHandler() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let typeRaw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 0
            let type = AVAudioSession.InterruptionType(rawValue: typeRaw)

            MainActor.assumeIsolated {
                guard let self else { return }
                if type == .began {
                    // Keep the run's playback intent even if the engine has
                    // already been stopped by iOS before this notification.
                    self.wasPlayingBeforeInterruption = self.playbackRequested
                    self.haltPlayback(deactivateSession: false)
                } else if type == .ended {
                    // `shouldResume` is only a system hint and can be absent.
                    // An active run is authoritative: resume unless the user
                    // paused or stopped while the interruption was in progress.
                    let shouldRestart = self.playbackRequested
                        && self.wasPlayingBeforeInterruption
                    self.wasPlayingBeforeInterruption = false
                    if shouldRestart {
                        self.beginPlayback()
                    }
                }
            }
        }
    }

    private func setupConfigChangeHandler() {
        configChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange,
            object: engine,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self,
                      self.playbackRequested,
                      !self.isStartingPlayback else { return }
                self.restartAfterConfigurationChange()
            }
        }
    }

    private func restartAfterConfigurationChange() {
        player.stop()
        engine.stop()
        engine.reset()
        isPlaying = false
        beginPlayback()
    }

    static func beatInterval(bpm: Int) -> Double {
        60.0 / Double(max(1, bpm))
    }

    // MARK: - Synthesis

    /// Builds one continuous two-beat measure (accent + soft beat + silence).
    /// Looping this buffer keeps rendering independent of main-thread scheduling in the background.
    private func makeLoopBuffer() -> AVAudioPCMBuffer? {
        let outputFormat = engine.mainMixerNode.outputFormat(forBus: 0)
        let rate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44_100
        let channels = outputFormat.channelCount > 0 ? outputFormat.channelCount : 2
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: rate,
            channels: channels
        ) else { return nil }

        let beatDuration = Self.beatInterval(bpm: bpm)
        let measureDuration = beatDuration * 2
        let frameCount = AVAudioFrameCount(ceil(rate * measureDuration))
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(
                pcmFormat: format,
                frameCapacity: frameCount
              ),
              let channelData = buffer.floatChannelData else { return nil }

        buffer.frameLength = frameCount
        let clickDuration = (soundType == .bell || soundType == .woodLo) ? 0.080 : 0.040

        for channel in 0..<Int(channels) {
            let samples = channelData[channel]
            for frame in 0..<Int(frameCount) {
                let measureTime = Double(frame) / rate
                if measureTime < clickDuration {
                    samples[frame] = Float(sample(t: measureTime, high: true))
                } else {
                    let secondBeatTime = measureTime - beatDuration
                    samples[frame] = secondBeatTime >= 0 && secondBeatTime < clickDuration
                        ? Float(sample(t: secondBeatTime, high: false))
                        : 0
                }
            }
        }
        return buffer
    }

    // high = beat 1 (higher pitch), low = beat 2 (lower pitch)
    private func sample(t: Double, high: Bool) -> Double {
        let pitchMult: Double = high ? 1.0 : 0.6

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

        case .woodHi:
            let env = exp(-t * 120)
            let f1 = 1400 * pitchMult, f2 = 2100 * pitchMult
            return (sin(2 * .pi * f1 * t) * 0.6 + sin(2 * .pi * f2 * t) * 0.4) * env

        case .woodLo:
            let env = exp(-t * 80)
            let f1 = 400 * pitchMult, f2 = 600 * pitchMult
            return (sin(2 * .pi * f1 * t) * 0.6 + sin(2 * .pi * f2 * t) * 0.4) * env
        }
    }

    // MARK: - Playback

    func start() {
        playbackRequested = true
        beginPlayback()
    }

    private func beginPlayback() {
        guard playbackRequested, !isStartingPlayback else { return }
        isStartingPlayback = true
        defer { isStartingPlayback = false }

        do {
            try activateAudioSession()
            // Configure the engine only after the session is active so the
            // player connection uses the real hardware route and format.
            prepareIfNeeded()
            if !engine.isRunning {
                engine.prepare()
                try engine.start()
            }

            // The mixer output format is reliable only after the engine has
            // started. Building the buffer earlier can result in silent playback
            // on routes whose sample rate/channels are negotiated lazily.
            guard let buffer = makeLoopBuffer() else {
                throw MetronomeError.couldNotCreateLoopBuffer
            }

            player.stop()
            loopBuffer = buffer
            player.scheduleBuffer(buffer, at: nil, options: .loops)
            player.play()
            isPlaying = true
            lastPlaybackError = nil
        } catch {
            player.stop()
            engine.stop()
            isPlaying = false
            lastPlaybackError = error.localizedDescription
            print("⚠️ [Metronome] Could not start playback: \(error)")
        }
    }

    func stop() {
        playbackRequested = false
        wasPlayingBeforeInterruption = false
        haltPlayback(deactivateSession: true)
    }

    func pause() {
        playbackRequested = false
        wasPlayingBeforeInterruption = false
        haltPlayback(deactivateSession: true)
    }

    private func haltPlayback(deactivateSession: Bool) {
        isPlaying = false
        guard isPrepared else { return }
        player.stop()
        engine.pause()
        loopBuffer = nil
        if deactivateSession {
            deactivateAudioSession()
        }
    }

    func resume() {
        playbackRequested = true
        beginPlayback()
    }

    func updateBPM(_ newBPM: Int) {
        guard bpm != newBPM else { return }
        bpm = newBPM
        rebuildLoopIfPlaying()
    }

    func updateSoundType(_ type: SoundType) {
        guard soundType != type else { return }
        soundType = type
        rebuildLoopIfPlaying()
    }

    private func rebuildLoopIfPlaying() {
        guard playbackRequested else { return }
        beginPlayback()
    }
}

private enum MetronomeError: LocalizedError {
    case couldNotCreateLoopBuffer

    var errorDescription: String? {
        switch self {
        case .couldNotCreateLoopBuffer:
            "Could not create the metronome audio buffer."
        }
    }
}
