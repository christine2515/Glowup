import SwiftUI
import SwiftData

/// GitHub-contribution-style heatmap of workout days. Darker squares = more
/// workouts that day (gym sessions + completed runs).
struct CalendarHeatmapView: View {
    @Query private var sessions: [WorkoutSession]
    @Query private var runs: [RunEntry]

    /// How many weeks back to show.
    private let weeks = 26
    private let cell: CGFloat = 15
    private let spacing: CGFloat = 3

    private var days: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let start = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: weekStart) ?? today
        var result: [Date] = []
        var d = start
        while d <= today {
            result.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? today.addingTimeInterval(86400)
        }
        return result
    }

    /// startOfDay -> workout count.
    private var counts: [Date: Int] {
        let cal = Calendar.current
        var map: [Date: Int] = [:]
        for s in sessions {
            map[cal.startOfDay(for: s.date), default: 0] += 1
        }
        for r in runs where r.completed {
            map[cal.startOfDay(for: r.date), default: 0] += 1
        }
        return map
    }

    private var totalInRange: Int {
        guard let first = days.first else { return 0 }
        return counts.filter { $0.key >= first }.reduce(0) { $0 + $1.value }
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

    private let rows = Array(repeating: GridItem(.fixed(15), spacing: 3), count: 7)

    var body: some View {
        List {
            Section {
                HStack {
                    stat("\(totalInRange)", "workouts")
                    Divider()
                    stat("\(currentStreak)", "day streak")
                }
                .frame(maxWidth: .infinity)
            }

            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: spacing) {
                        ForEach(days, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color(for: counts[day] ?? 0))
                                .frame(width: cell, height: cell)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                HStack(spacing: 4) {
                    Text("Less").font(.caption2)
                    ForEach(0..<4) { level in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color(for: level))
                            .frame(width: 12, height: 12)
                    }
                    Text("More").font(.caption2)
                }
            }
        }
        .navigationTitle("Workout Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func color(for count: Int) -> Color {
        switch count {
        case 0: return Color.gray.opacity(0.15)
        case 1: return Color.green.opacity(0.45)
        case 2: return Color.green.opacity(0.7)
        default: return Color.green
        }
    }
}
