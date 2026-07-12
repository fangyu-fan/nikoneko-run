import CoreMotion

@Observable
@MainActor
final class MotionService {
    private(set) var steps: Int = 0
    private(set) var distance: Double = 0
    private(set) var calories: Double = 0
    private(set) var avgCadence: Int = 0

    private let pedometer = CMPedometer()
    private var startDate: Date?

    var weightKg: Double = 65
    var heightCm: Double = 170

    func startTracking() {
        startDate = Date()
        steps = 0; distance = 0; calories = 0; avgCadence = 0
        guard CMPedometer.isStepCountingAvailable() else { return }
        pedometer.startUpdates(from: startDate!) { [weak self] data, _ in
            guard let self, let data else { return }
            let steps = data.numberOfSteps.intValue
            let distance = data.distance?.doubleValue ?? 0
            let end = data.endDate
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.steps = steps
                self.distance = distance
                self.calories = Self.estimateCalories(
                    steps: steps,
                    weightKg: self.weightKg,
                    heightCm: self.heightCm
                )
                if let start = self.startDate, end.timeIntervalSince(start) > 0 {
                    self.avgCadence = Int(Double(steps) / (end.timeIntervalSince(start) / 60))
                }
            }
        }
    }

    func stopTracking() {
        pedometer.stopUpdates()
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
