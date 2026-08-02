import Foundation
import HealthKit

private struct HRUpdate: Sendable {
    let samples: [Int]
    let anchorData: Data?
}

@Observable
@MainActor
final class HeartRateService {
    enum HRSource: Equatable { case watch, none }

    private(set) var currentHR: Int = 0
    private(set) var avgHR: Int = 0
    private(set) var maxHR: Int = 0
    private(set) var source: HRSource = .none

    private var sampleCount: Int = 0
    private var sampleSum: Int = 0
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var queryAnchor: HKQueryAnchor?
    private let store = HKHealthStore()
    private var updateTask: Task<Void, Never>?
    private var streamContinuation: AsyncStream<HRUpdate>.Continuation?

    func startMonitoring() {
        sampleCount = 0; sampleSum = 0
        currentHR = 0; avgHR = 0; maxHR = 0; source = .none
        guard HKHealthStore.isHealthDataAvailable() else { return }
        startHealthKitQuery()
    }

    func stopMonitoring() {
        if let q = anchoredQuery { store.stop(q) }
        anchoredQuery = nil
        streamContinuation?.finish()
        streamContinuation = nil
        updateTask?.cancel()
        updateTask = nil
        source = .none
    }

    private func startHealthKitQuery() {
        let type = HKQuantityType(.heartRate)
        let unit = HKUnit(from: "count/min")

        let (stream, continuation) = AsyncStream.makeStream(of: HRUpdate.self)
        streamContinuation = continuation

        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: queryAnchor,
            limit: HKObjectQueryNoLimit
        ) { @Sendable _, newSamples, _, newAnchor, _ in
            let hrs = (newSamples as? [HKQuantitySample])?.map { Int($0.quantity.doubleValue(for: unit)) } ?? []
            let anchorData = newAnchor.flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
            continuation.yield(HRUpdate(samples: hrs, anchorData: anchorData))
        }
        query.updateHandler = { @Sendable _, newSamples, _, newAnchor, _ in
            let hrs = (newSamples as? [HKQuantitySample])?.map { Int($0.quantity.doubleValue(for: unit)) } ?? []
            let anchorData = newAnchor.flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
            continuation.yield(HRUpdate(samples: hrs, anchorData: anchorData))
        }
        anchoredQuery = query
        store.execute(query)
        source = .watch

        updateTask = Task { [weak self] in
            for await update in stream {
                guard let self else { return }
                if let data = update.anchorData {
                    self.queryAnchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
                }
                for hr in update.samples {
                    self.simulateSample(hr: hr)
                }
            }
        }
    }

    func simulateSample(hr: Int) {
        sampleCount += 1
        sampleSum += hr
        currentHR = hr
        if hr > maxHR { maxHR = hr }
        avgHR = sampleSum / sampleCount
        if source == .none { source = .watch }
    }
}
