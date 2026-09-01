import HealthKit

struct CSVSessionRecord: Equatable {
    let startDate: Date
    let durationMinutes: Double
    let distanceKilometers: Double
    let calories: Double
    let steps: Int
    let avgHR: Int
    let maxHR: Int
    let bpm: Int
}

enum CSVSessionCodec {
    static let header = "Date,Duration(min),Distance(km),Calories,Steps,AvgHR,MaxHR,BPM"

    enum DecodeError: Error {
        case invalidHeader
        case noValidRows
    }

    static func encode(sessions: [RunSession]) -> String {
        let dateFormatter = ISO8601DateFormatter()
        let locale = Locale(identifier: "en_US_POSIX")
        var rows = [header]
        rows.reserveCapacity(sessions.count + 1)

        for session in sessions {
            rows.append([
                dateFormatter.string(from: session.startDate),
                "\(Int(session.duration / 60))",
                String(format: "%.2f", locale: locale, session.distance / 1000),
                "\(Int(session.calories))",
                "\(session.steps)",
                "\(session.avgHR)",
                "\(session.maxHR)",
                "\(session.bpm)",
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    static func decode(_ content: String) throws -> [CSVSessionRecord] {
        let lines = content
            .split(whereSeparator: \.isNewline)
            .map(String.init)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard let firstLine = lines.first else { throw DecodeError.invalidHeader }
        let normalizedHeader = firstLine
            .replacingOccurrences(of: "\u{feff}", with: "")
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: ",")
        guard normalizedHeader == header else { throw DecodeError.invalidHeader }

        let dateFormatter = ISO8601DateFormatter()
        let records = lines.dropFirst().compactMap { line -> CSVSessionRecord? in
            let columns = line
                .split(separator: ",", omittingEmptySubsequences: false)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard columns.count == 8,
                  let date = dateFormatter.date(from: columns[0]),
                  let durationMinutes = Double(columns[1]),
                  let distanceKilometers = Double(columns[2]),
                  let calories = Double(columns[3]),
                  let steps = Int(columns[4]),
                  let avgHR = Int(columns[5]),
                  let maxHR = Int(columns[6]),
                  let bpm = Int(columns[7])
            else { return nil }

            return CSVSessionRecord(
                startDate: date,
                durationMinutes: durationMinutes,
                distanceKilometers: distanceKilometers,
                calories: calories,
                steps: steps,
                avgHR: avgHR,
                maxHR: maxHR,
                bpm: bpm
            )
        }
        guard !records.isEmpty else { throw DecodeError.noValidRows }
        return records
    }
}

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
        let csv = CSVSessionCodec.encode(sessions: sessions)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("niko_export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
