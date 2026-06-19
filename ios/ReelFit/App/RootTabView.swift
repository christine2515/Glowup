import SwiftUI

struct RootTabView: View {
    @Environment(PendingReels.self) private var pending
    @State private var config = AppConfig.shared

    var body: some View {
        content
            .tint(config.theme.accent)
            .fontDesign(.rounded)
    }

    private var content: some View {
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
