import SwiftUI

struct RootTabView: View {
    @Environment(PendingReels.self) private var pending
    @State private var config = AppConfig.shared

    var body: some View {
        content
            .tint(config.theme.accent)
            .onAppear { applyAppearance(config.theme) }
            .onChange(of: config.themeID) { applyAppearance(config.theme) }
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

            HealthView()
                .tabItem { Label("Me", systemImage: "heart") }
        }
    }

    /// Marcellus navigation titles + cream bars matching the theme.
    private func applyAppearance(_ t: AppTheme) {
        let ink = UIColor(t.ink)

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        nav.backgroundColor = UIColor(t.page)
        if let large = UIFont(name: "Marcellus", size: 32) {
            nav.largeTitleTextAttributes = [.font: large, .foregroundColor: ink]
        }
        if let inline = UIFont(name: "Marcellus", size: 18) {
            nav.titleTextAttributes = [.font: inline, .foregroundColor: ink]
        }
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundColor = UIColor(t.surface)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}
