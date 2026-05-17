import Foundation
import HealthKit

@Observable
@MainActor
final class HeartRateService {
    enum HRSource: Equatable { case watch, ble, none }

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
        currentHR = 0; avgHR = 0; maxHR = 0

        if HKHealthStore.isHealthDataAvailable() {
            startHealthKitQuery()
        }
    }

    private func startHealthKitQuery() {
        let type = HKQuantityType(.heartRate)
        let query = HKAnchoredObjectQuery(
            type: type,
            predicate: HKQuery.predicateForSamples(withStart: Date(), end: nil),
            anchor: queryAnchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, newSamples, _, newAnchor, _ in
            Task { @MainActor [weak self] in
                self?.queryAnchor = newAnchor
                self?.processHKSamples(newSamples as? [HKQuantitySample])
            }
        }
        query.updateHandler = { [weak self] _, newSamples, _, newAnchor, _ in
            Task { @MainActor [weak self] in
                self?.queryAnchor = newAnchor
                self?.processHKSamples(newSamples as? [HKQuantitySample])
            }
        }
        anchoredQuery = query
        store.execute(query)
        source = .watch
    }

    private func processHKSamples(_ hkSamples: [HKQuantitySample]?) {
        guard let hkSamples else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        hkSamples.map { Int($0.quantity.doubleValue(for: unit)) }.forEach { simulateSample(hr: $0) }
    }

    func simulateSample(hr: Int) {
        currentHR = hr
        samples.append(hr)
        maxHR = max(maxHR, hr)
        avgHR = samples.reduce(0, +) / samples.count
        if source == .none { source = .watch }
    }

    func stopMonitoring() {
        if let q = anchoredQuery { store.stop(q) }
        anchoredQuery = nil
        source = .none
    }
}
