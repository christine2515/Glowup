import SwiftUI
import SwiftData

/// Nutrition. Phase 3 adds: calorie/macro target, meal log with food search
/// (USDA), macro rings vs target, and AI "what should I make?" suggestions.
struct NutritionView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Nutrition coming in Phase 3",
                systemImage: "fork.knife",
                description: Text("Set calorie/macro targets, log meals with a food search, see macro rings, and get AI meal suggestions that fit your remaining macros.")
            )
            .navigationTitle("Nutrition")
        }
    }
}
