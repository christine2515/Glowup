import SwiftUI
import SwiftData

/// Full workout calendar: a year heatmap plus totals and current streak.
struct CalendarHeatmapView: View {
    @Query private var sessions: [WorkoutSession]
    @Query private var runs: [RunEntry]

    private var counts: [Date: Int] {
        let cal = Calendar.current
        var map: [Date: Int] = [:]
        for s in sessions { map[cal.startOfDay(for: s.date), default: 0] += 1 }
        for r in runs where r.completed { map[cal.startOfDay(for: r.date), default: 0] += 1 }
        return map
    }

    private var totalThisYear: Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -365, to: cal.startOfDay(for: Date())) ?? .now
        return counts.filter { $0.key >= start }.reduce(0) { $0 + $1.value }
    }

    private var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var d = cal.startOfDay(for: Date())
        while (counts[d] ?? 0) > 0 {
            streak += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return streak
    }

    var body: some View {
        List {
            Section {
                HStack {
                    stat("\(totalThisYear)", "this year")
                    Divider()
                    stat("\(currentStreak)", "day streak")
                }
                .frame(maxWidth: .infinity)
            }

            Section {
                WorkoutHeatmap(weeks: 53, cell: 14)
            } footer: {
                HeatmapLegend()
            }
        }
        .navigationTitle("Workout Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .airyBackground(AppConfig.shared.theme)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
