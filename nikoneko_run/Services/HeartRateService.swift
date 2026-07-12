import Foundation
import HealthKit

@Observable
@MainActor
final class HeartRateService {
    enum HRSource: Equatable { case watch, none }

    private(set) var currentHR: Int = 0
    private(set) var avgHR: Int = 0
    private(set) var maxHR: Int = 0
    private(set) var source: HRSource = .none

    private var samples: [Int] = []
    private var anchoredQuery: HKAnchoredObjectQuery?
    private var queryAnchor: HKQueryAnchor?
    private let store = HKHealthStore()

    func startMonitoring() {
        samples = []
        currentHR = 0; avgHR = 0; maxHR = 0; source = .none
        guard HKHealthStore.isHealthDataAvailable() else { return }
        startHealthKitQuery()
    }

    func stopMonitoring() {
        if let q = anchoredQuery { store.stop(q) }
        anchoredQuery = nil
        source = .none
    }

    private func startHealthKitQuery() {
        let type = HKQuantityType(.heartRate)
        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: queryAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, newSamples, _, newAnchor, _ in
            let samples = newSamples as? [HKQuantitySample]
            DispatchQueue.main.async { [weak self] in
                self?.queryAnchor = newAnchor
                self?.processHKSamples(samples)
            }
        }
        query.updateHandler = { [weak self] _, newSamples, _, newAnchor, _ in
            let samples = newSamples as? [HKQuantitySample]
            DispatchQueue.main.async { [weak self] in
                self?.queryAnchor = newAnchor
                self?.processHKSamples(samples)
            }
        }
        anchoredQuery = query
        store.execute(query)
        source = .watch
    }

    private func processHKSamples(_ hkSamples: [HKQuantitySample]?) {
        guard let hkSamples, !hkSamples.isEmpty else { return }
        let unit = HKUnit(from: "count/min")
        hkSamples.map { Int($0.quantity.doubleValue(for: unit)) }.forEach { simulateSample(hr: $0) }
    }

    // Used by unit tests and for injecting HR values in debug/preview contexts.
    func simulateSample(hr: Int) {
        samples.append(hr)
        currentHR = hr
        if hr > maxHR { maxHR = hr }
        avgHR = samples.reduce(0, +) / samples.count
        if source == .none { source = .watch }
    }
}
