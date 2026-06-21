import SwiftUI
import SwiftData

/// Reusable GitHub-style activity heatmap (workouts per day). Darker = more.
/// Used compact on the Today page and larger on the calendar screen.
struct WorkoutHeatmap: View {
    var weeks: Int = 53
    var cell: CGFloat = 12
    var showMonthLabels: Bool = true

    @Query private var sessions: [WorkoutSession]
    @Query private var runs: [RunEntry]
    @State private var config = AppConfig.shared

    private let spacing: CGFloat = 3
    private let cal = Calendar.current

    /// Columns of 7 days each, oldest → newest, aligned to week starts.
    private var columns: [[Date]] {
        let today = cal.startOfDay(for: Date())
        let weekStart = cal.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        let start = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: weekStart) ?? today
        var cols: [[Date]] = []
        var colStart = start
        for _ in 0..<weeks {
            var col: [Date] = []
            for d in 0..<7 {
                col.append(cal.date(byAdding: .day, value: d, to: colStart) ?? colStart)
            }
            cols.append(col)
            colStart = cal.date(byAdding: .weekOfYear, value: 1, to: colStart) ?? colStart
        }
        return cols
    }

    private var counts: [Date: Int] {
        var map: [Date: Int] = [:]
        for s in sessions { map[cal.startOfDay(for: s.date), default: 0] += 1 }
        for r in runs where r.completed { map[cal.startOfDay(for: r.date), default: 0] += 1 }
        return map
    }

    var body: some View {
        let cols = columns
        let data = counts
        let today = cal.startOfDay(for: Date())

        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: spacing) {
                    if showMonthLabels {
                        HStack(spacing: spacing) {
                            ForEach(cols.indices, id: \.self) { i in
                                Text(monthLabel(for: i, cols: cols))
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .frame(width: cell, alignment: .leading)
                            }
                        }
                    }
                    HStack(spacing: spacing) {
                        ForEach(cols.indices, id: \.self) { i in
                            VStack(spacing: spacing) {
                                ForEach(0..<7, id: \.self) { r in
                                    let day = cols[i][r]
                                    RoundedRectangle(cornerRadius: 2.5)
                                        .fill(color(for: day, count: data[day] ?? 0, today: today))
                                        .frame(width: cell, height: cell)
                                }
                            }
                            .id(i)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .onAppear { proxy.scrollTo(cols.indices.last, anchor: .trailing) }
        }
    }

    private func monthLabel(for i: Int, cols: [[Date]]) -> String {
        let m = cal.component(.month, from: cols[i][0])
        if i == 0 || m != cal.component(.month, from: cols[i - 1][0]) {
            return cols[i][0].formatted(.dateTime.month(.abbreviated))
        }
        return ""
    }

    private func color(for day: Date, count: Int, today: Date) -> Color {
        if day > today { return Color.gray.opacity(0.05) }   // future
        switch count {
        case 0: return Color.gray.opacity(0.13)
        case 1: return config.theme.heat.opacity(0.4)
        case 2: return config.theme.heat.opacity(0.7)
        default: return config.theme.heat
        }
    }
}

/// The Less→More legend swatch row.
struct HeatmapLegend: View {
    @State private var config = AppConfig.shared
    var body: some View {
        HStack(spacing: 4) {
            Text("Less").font(.caption2).foregroundStyle(.secondary)
            swatch(Color.gray.opacity(0.13))
            swatch(config.theme.heat.opacity(0.4))
            swatch(config.theme.heat.opacity(0.7))
            swatch(config.theme.heat)
            Text("More").font(.caption2).foregroundStyle(.secondary)
        }
    }
    private func swatch(_ c: Color) -> some View {
        RoundedRectangle(cornerRadius: 2.5).fill(c).frame(width: 12, height: 12)
    }
}
