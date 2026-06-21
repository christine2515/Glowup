import SwiftUI
import SwiftData

/// Daily, training-focused dashboard: today's activity, this week at a glance,
/// hydration, and weight.
struct TodayView: View {
    @State private var config = AppConfig.shared
    @State private var health = HealthKitManager.shared

    @Query private var waterLogs: [WaterLog]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]
    @Query private var runs: [RunEntry]

    private var waterToday: Double {
        waterLogs.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amountML }
    }
    private var todaySessions: [WorkoutSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
    }
    private var todayRuns: [RunEntry] {
        runs.filter { $0.completed && Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date > $1.date }
    }
    private var workoutsThisWeek: Int {
        let cal = Calendar.current
        guard let week = cal.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        let s = sessions.filter { week.contains($0.date) }.count
        let r = runs.filter { $0.completed && week.contains($0.date) }.count
        return s + r
    }

    var body: some View {
        NavigationStack {
            List {
                heroHeader

                Section {
                    statRow(icon: "flame.fill", title: "This week",
                            value: "\(workoutsThisWeek)", unit: "workouts")
                    statRow(icon: "shoeprints.fill", title: "Steps", value: "\(health.todaySteps)", unit: "")
                } header: { sectionTitle("Today") }

                Section {
                    WorkoutHeatmap(weeks: 53, cell: 11)
                        .padding(.vertical, 2)
                } header: {
                    sectionTitle("Your year")
                } footer: {
                    HeatmapLegend()
                }

                if !todaySessions.isEmpty || !todayRuns.isEmpty {
                    Section {
                        ForEach(todaySessions) { s in
                            Label(s.templateTitle.isEmpty ? "Workout" : s.templateTitle,
                                  systemImage: "dumbbell.fill")
                        }
                        ForEach(todayRuns) { run in
                            Label {
                                Text("\(run.name.isEmpty ? "Run" : run.name) · \(run.actualDistanceKm ?? 0, specifier: "%.1f") km")
                            } icon: {
                                Image(systemName: "figure.run")
                            }
                        }
                    } header: { sectionTitle("Logged today") }
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Water", systemImage: "drop.fill")
                            Spacer()
                            Text("\(Int(waterToday)) / \(Int(config.waterGoalML)) ml")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        ProgressView(value: min(waterToday / max(config.waterGoalML, 1), 1))
                            .tint(config.theme.accent)
                    }
                    .padding(.vertical, 2)

                    if let latest = metrics.first {
                        HStack {
                            Label("Weight", systemImage: "scalemass.fill")
                            Spacer()
                            Text(WeightFormat.display(latest.weightKg, metric: config.useMetric))
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: { sectionTitle("Habits") }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .airyBackground(config.theme)
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
            .refreshable {
                if health.authorized { await health.refreshTodaySteps() }
            }
            .task {
                if health.authorized { await health.refreshTodaySteps() }
            }
        }
    }

    // MARK: - Pieces

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.largeTitle.bold())
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: "Good morning ☀️"
        case 12..<17: "Good afternoon 🌸"
        case 17..<22: "Good evening 🌙"
        default: "Hey 💪"
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(config.theme.accent)
            .textCase(nil)
    }

    private func statRow(icon: String, title: String, value: String, unit: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
            Spacer()
            Text(value).font(.title3.bold()).monospacedDigit()
            if !unit.isEmpty {
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
