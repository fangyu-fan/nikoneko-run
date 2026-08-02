import HealthKit

@Observable
@MainActor
final class HealthKitService {
    static let shared = HealthKitService()
    private let store = HKHealthStore()

    func requestPermissions() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let read: Set<HKObjectType> = [
            HKQuantityType(.heartRate),
            HKQuantityType(.bodyMass),
            HKQuantityType(.height)
        ]
        let write: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.heartRate),
            HKQuantityType(.distanceWalkingRunning)
        ]
        try? await store.requestAuthorization(toShare: write, read: read)
    }

    func writeSession(_ session: RunSession) {
        guard session.duration > 0 else { return }
        let start = session.startDate
        let end = start.addingTimeInterval(session.duration)
        let calories = session.calories
        let distance = session.distance
        let store = self.store

        Task {
            let config = HKWorkoutConfiguration()
            config.activityType = .running
            let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: nil)
            try? await builder.beginCollection(at: start)

            if calories > 0 {
                let energySample = HKQuantitySample(
                    type: HKQuantityType(.activeEnergyBurned),
                    quantity: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
                    start: start, end: end
                )
                try? await builder.addSamples([energySample])
            }

            if distance > 0 {
                let distSample = HKQuantitySample(
                    type: HKQuantityType(.distanceWalkingRunning),
                    quantity: HKQuantity(unit: .meter(), doubleValue: distance),
                    start: start, end: end
                )
                try? await builder.addSamples([distSample])
            }

            try? await builder.endCollection(at: end)
            try? await builder.finishWorkout()
        }
    }

    func exportCSV(sessions: [RunSession]) -> URL? {
        var csv = "Date,Duration(min),Distance(km),Calories,Steps,AvgHR,MaxHR,BPM\n"
        let df = ISO8601DateFormatter()
        for s in sessions {
            csv += "\(df.string(from: s.startDate)),"
            csv += "\(Int(s.duration / 60)),"
            csv += String(format: "%.2f", s.distance / 1000) + ","
            csv += "\(Int(s.calories)),"
            csv += "\(s.steps),"
            csv += "\(s.avgHR),"
            csv += "\(s.maxHR),"
            csv += "\(s.bpm)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("niko_export.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}
