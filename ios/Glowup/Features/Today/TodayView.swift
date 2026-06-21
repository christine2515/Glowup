import SwiftUI
import SwiftData

/// Daily, training-focused dashboard styled to the Glowup design.
struct TodayView: View {
    @State private var config = AppConfig.shared
    @State private var health = HealthKitManager.shared

    @Query private var waterLogs: [WaterLog]
    @Query private var proteinLogs: [ProteinLog]
    @Query private var supplements: [Supplement]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]
    @Query private var runs: [RunEntry]

    private var t: AppTheme { config.theme }

    private var waterToday: Double {
        waterLogs.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amountML }
    }
    private var proteinToday: Double {
        proteinLogs.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.grams }
    }
    private var supplementsTaken: Int {
        supplements.filter { $0.takenCount() >= $0.dailyTarget && $0.dailyTarget > 0 }.count
    }
    private var workoutsThisWeek: Int {
        let cal = Calendar.current
        guard let week = cal.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        let s = sessions.filter { week.contains($0.date) }.count
        let r = runs.filter { $0.completed && week.contains($0.date) }.count
        return s + r
    }
    private var activeDays: Int {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -365, to: cal.startOfDay(for: Date())) ?? .now
        var days = Set<Date>()
        for s in sessions where s.date >= start { days.insert(cal.startOfDay(for: s.date)) }
        for r in runs where r.completed && r.date >= start { days.insert(cal.startOfDay(for: r.date)) }
        return days.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                hero
                statRow
                yearCard
                habitsCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(t.page.ignoresSafeArea())
        .refreshable { if health.authorized { await health.refreshTodaySteps() } }
        .task { if health.authorized { await health.refreshTodaySteps() } }
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(greeting).font(.serif(31)).foregroundStyle(t.ink)
            Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                .font(.sans(14, .medium)).foregroundStyle(t.ink2)
        }
        .padding(.vertical, 6)
    }

    private var statRow: some View {
        HStack(spacing: 13) {
            statTile(title: "This week", value: "\(workoutsThisWeek)", sub: "workouts", bg: t.accentSoft2)
            statTile(title: "Steps today", value: stepsString, sub: "Apple Health", bg: t.secondarySoft)
        }
    }

    private var yearCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("Your year").font(.serif(17)).foregroundStyle(t.ink)
                Spacer()
                Text("\(activeDays) active days").font(.sans(11, .semibold)).foregroundStyle(t.ink2)
            }
            HStack(spacing: 0) {
                ForEach(Calendar.current.shortMonthSymbols, id: \.self) { m in
                    Text(m).font(.sans(8.5, .semibold)).foregroundStyle(t.ink2)
                        .frame(maxWidth: .infinity)
                }
            }
            WorkoutHeatmap(weeks: 53, cell: 4, showMonthLabels: false)
            HStack { Spacer(); HeatmapLegend() }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowCard(t, padding: 16, radius: 22)
    }

    private var habitsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Habits").font(.serif(17)).foregroundStyle(t.ink)

            habitBar(icon: "💧 Water", value: waterToday, goal: config.waterGoalML,
                     unit: "ml", fill: t.secondary)
            habitBar(icon: "🥚 Protein", value: proteinToday, goal: config.proteinGoalG,
                     unit: "g", fill: t.accent)

            if !supplements.isEmpty {
                HStack {
                    Text("💊 Supplements").font(.sans(13, .semibold)).foregroundStyle(t.ink)
                    Spacer()
                    Text("\(supplementsTaken)/\(supplements.count) taken")
                        .font(.sans(13, .semibold)).foregroundStyle(t.ink2)
                }
            }

            Divider().overlay(t.ring)

            HStack {
                Text("⚖️ Body weight").font(.sans(13, .semibold)).foregroundStyle(t.ink)
                Spacer()
                if let latest = metrics.first {
                    Text(WeightFormat.display(latest.weightKg, metric: config.useMetric))
                        .font(.sans(15, .semibold)).foregroundStyle(t.ink)
                } else {
                    Text("—").foregroundStyle(t.ink2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowCard(t, padding: 16, radius: 22)
    }

    // MARK: - Pieces

    private func habitBar(icon: String, value: Double, goal: Double, unit: String, fill: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(icon).font(.sans(13, .semibold)).foregroundStyle(t.ink)
                Spacer()
                Text("\(Int(value)) / \(Int(goal)) \(unit)")
                    .font(.sans(13, .semibold)).foregroundStyle(t.ink2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(t.accentSoft2)
                    Capsule().fill(fill)
                        .frame(width: geo.size.width * min(value / max(goal, 1), 1))
                }
            }
            .frame(height: 10)
        }
    }

    private func statTile(title: String, value: String, sub: String, bg: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.sans(12, .semibold)).foregroundStyle(t.ink2)
            Text(value).font(.serif(34)).foregroundStyle(t.ink)
            Text(sub).font(.sans(12, .medium)).foregroundStyle(t.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(bg, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var stepsString: String {
        let f = NumberFormatter(); f.numberStyle = .decimal
        return f.string(from: NSNumber(value: health.todaySteps)) ?? "\(health.todaySteps)"
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: "Good morning ☀️"
        case 12..<17: "Good afternoon 🌸"
        case 17..<22: "Good evening 🌙"
        default: "Hey 💪"
        }
    }
}
