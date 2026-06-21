import Foundation
import HealthKit
import Observation

/// Reads step count from Apple Health. Steps are read live, not stored.
@Observable
final class HealthKitManager {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()
    var todaySteps: Int = 0
    var authorized = false

    private init() {}

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        let stepType = HKQuantityType(.stepCount)
        let bodyMass = HKQuantityType(.bodyMass)
        do {
            try await store.requestAuthorization(toShare: [bodyMass], read: [stepType, bodyMass])
            authorized = true
            await refreshTodaySteps()
        } catch {
            authorized = false
        }
    }

    @MainActor
    func refreshTodaySteps() async {
        guard isAvailable else { return }
        let steps = await fetchTodaySteps()
        self.todaySteps = steps
    }

    private func fetchTodaySteps() async -> Int {
        let stepType = HKQuantityType(.stepCount)
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, stats, _ in
                let count = stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(count))
            }
            store.execute(query)
        }
    }
}
