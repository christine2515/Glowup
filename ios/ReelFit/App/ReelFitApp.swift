import SwiftUI
import SwiftData

@main
struct ReelFitApp: App {
    let container: ModelContainer
    @State private var pending = PendingReels()

    init() {
        container = Self.makeContainer()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(pending)
                .task { pending.refresh() }
        }
        .modelContainer(container)
    }

    /// Builds the store. iCloud sync is opt-in via Settings (needs the CloudKit
    /// entitlement + a paid Apple Developer account); if enabling it fails
    /// (e.g. missing entitlement), we fall back to a local-only store so the app
    /// still launches.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            WorkoutTemplate.self, Exercise.self,
            WorkoutSession.self, SetLog.self, RunEntry.self,
            NutritionTarget.self, Meal.self, FoodEntry.self,
            BodyMetric.self, WaterLog.self, Supplement.self, SupplementLog.self,
        ])

        if AppConfig.iCloudSyncEnabled {
            let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
                return container
            }
            // Fall through to local-only on failure.
        }

        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [local])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}

/// Holds reels handed off from the Share Extension, drained from the App Group.
@Observable
final class PendingReels {
    var reels: [SharedReel] = []

    func refresh() {
        let drained = ShareInbox.drain()
        guard !drained.isEmpty else { return }
        reels.append(contentsOf: drained)
    }

    func remove(_ reel: SharedReel) {
        reels.removeAll { $0.id == reel.id }
    }
}
