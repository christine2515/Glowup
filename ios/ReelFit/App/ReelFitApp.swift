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

    /// Local-only store for now. To enable iCloud sync (Phase 5, needs a paid
    /// Apple Developer account + CloudKit entitlement), change
    /// `cloudKitDatabase: .none` to `.automatic`.
    static func makeContainer() -> ModelContainer {
        let schema = Schema([
            WorkoutTemplate.self, Exercise.self,
            WorkoutSession.self, SetLog.self, RunEntry.self,
            NutritionTarget.self, Meal.self, FoodEntry.self,
            BodyMetric.self, WaterLog.self, Supplement.self, SupplementLog.self,
        ])
        let config = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: [config])
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
