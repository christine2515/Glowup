import SwiftUI
import SwiftData

/// Daily dashboard pulling together training, nutrition, hydration,
/// supplements, steps, and weight.
struct TodayView: View {
    @State private var config = AppConfig.shared
    @State private var health = HealthKitManager.shared

    @Query(sort: \NutritionTarget.effectiveDate, order: .reverse) private var targets: [NutritionTarget]
    @Query(sort: \Meal.date, order: .reverse) private var allMeals: [Meal]
    @Query private var waterLogs: [WaterLog]
    @Query(sort: \Supplement.createdAt) private var supplements: [Supplement]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]
    @Query private var runs: [RunEntry]

    private var target: NutritionTarget? { targets.first }
    private var todayMeals: [Meal] { allMeals.filter { Calendar.current.isDateInToday($0.date) } }
    private var consumed: MacroTotals {
        todayMeals.reduce(into: MacroTotals()) {
            $0.kcal += $1.totalKcal; $0.protein += $1.totalProtein
            $0.carbs += $1.totalCarbs; $0.fat += $1.totalFat
        }
    }
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
    private var supplementsTaken: Int {
        supplements.reduce(0) { acc, s in
            acc + ((s.logs ?? []).contains { Calendar.current.isDateInToday($0.date) } ? 1 : 0)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Nutrition") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            MacroRing(label: "Calories", value: consumed.kcal, target: target?.kcal ?? 2000, unit: "kcal", color: .orange)
                            MacroRing(label: "Protein", value: consumed.protein, target: target?.proteinG ?? 150, unit: "g", color: .pink)
                            MacroRing(label: "Carbs", value: consumed.carbs, target: target?.carbsG ?? 200, unit: "g", color: .blue)
                            MacroRing(label: "Fat", value: consumed.fat, target: target?.fatG ?? 60, unit: "g", color: .green)
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Activity") {
                    LabeledContent("Steps", value: "\(health.todaySteps)")
                    LabeledContent("Workouts logged", value: "\(todaySessions.count)")
                    ForEach(todaySessions) { s in
                        LabeledContent(s.templateTitle.isEmpty ? "Workout" : s.templateTitle,
                                       value: s.date.formatted(date: .omitted, time: .shortened))
                    }
                    ForEach(todayRuns) { run in
                        LabeledContent {
                            Text("\(run.actualDistanceKm ?? 0, specifier: "%.1f") km")
                        } label: {
                            Label(run.name.isEmpty ? "Run" : run.name,
                                  systemImage: "figure.run")
                        }
                    }
                }

                Section("Habits") {
                    ProgressView(value: min(waterToday / max(config.waterGoalML, 1), 1)) {
                        Text("Water · \(Int(waterToday))/\(Int(config.waterGoalML)) ml").font(.subheadline)
                    }
                    if !supplements.isEmpty {
                        LabeledContent("Supplements", value: "\(supplementsTaken)/\(supplements.count) taken")
                    }
                    if let latest = metrics.first {
                        LabeledContent("Weight",
                                       value: WeightFormat.display(latest.weightKg, metric: config.useMetric))
                    }
                }
            }
            .navigationTitle(Date().formatted(date: .complete, time: .omitted))
            .refreshable {
                if health.authorized { await health.refreshTodaySteps() }
            }
            .task {
                if health.authorized { await health.refreshTodaySteps() }
            }
        }
    }
}
