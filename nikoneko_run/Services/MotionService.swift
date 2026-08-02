import CoreMotion

private struct PedometerUpdate: Sendable {
    let steps: Int
    let distance: Double
    let endDate: Date
}

@Observable
@MainActor
final class MotionService {
    private(set) var steps: Int = 0
    private(set) var distance: Double = 0
    private(set) var calories: Double = 0
    private(set) var avgCadence: Int = 0

    private let pedometer = CMPedometer()
    private var startDate: Date?
    private var updateTask: Task<Void, Never>?
    private var streamContinuation: AsyncStream<PedometerUpdate>.Continuation?

    var weightKg: Double = 65
    var heightCm: Double = 170

    func startTracking() {
        startDate = Date()
        steps = 0; distance = 0; calories = 0; avgCadence = 0
        guard CMPedometer.isStepCountingAvailable() else { return }

        let (stream, continuation) = AsyncStream.makeStream(of: PedometerUpdate.self)
        streamContinuation = continuation

        pedometer.startUpdates(from: startDate!) { @Sendable data, _ in
            guard let data else { return }
            continuation.yield(PedometerUpdate(
                steps: data.numberOfSteps.intValue,
                distance: data.distance?.doubleValue ?? 0,
                endDate: data.endDate
            ))
        }

        updateTask = Task { [weak self] in
            for await update in stream {
                guard let self else { return }
                self.steps = update.steps
                self.distance = update.distance
                self.calories = Self.estimateCalories(
                    steps: update.steps,
                    weightKg: self.weightKg,
                    heightCm: self.heightCm
                )
                if let start = self.startDate, update.endDate.timeIntervalSince(start) > 0 {
                    self.avgCadence = Int(Double(update.steps) / (update.endDate.timeIntervalSince(start) / 60))
                }
            }
        }
    }

    func stopTracking() {
        pedometer.stopUpdates()
        streamContinuation?.finish()
        streamContinuation = nil
        updateTask?.cancel()
        updateTask = nil
    }

    static func requestAuthorization() async {
        guard CMPedometer.isStepCountingAvailable() else { return }
        let manager = CMMotionActivityManager()
        _ = await withCheckedContinuation { (cont: CheckedContinuation<Bool, Never>) in
            var resumed = false
            manager.queryActivityStarting(from: Date(), to: Date(), to: .main) { _, _ in
                guard !resumed else { return }
                resumed = true
                cont.resume(returning: true)
            }
        }
    }

    static func estimateCalories(steps: Int, weightKg: Double, heightCm: Double) -> Double {
        let strideM = heightCm * 0.415 / 100
        let distKm = Double(steps) * strideM / 1000
        return distKm * weightKg * 1.036
    }
}
