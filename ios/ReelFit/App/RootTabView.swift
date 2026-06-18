import SwiftUI

struct RootTabView: View {
    @Environment(PendingReels.self) private var pending

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }

            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell") }
                .badge(pending.reels.count)

            TrainView()
                .tabItem { Label("Train", systemImage: "figure.run") }

            NutritionView()
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }

            HealthView()
                .tabItem { Label("Me", systemImage: "heart") }
        }
    }
}
