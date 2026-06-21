import SwiftUI
import SwiftData

/// "Me" tab: Apple Health steps, water, body weight, and settings.
struct HealthView: View {
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared
    @State private var health = HealthKitManager.shared

    @Query private var waterLogs: [WaterLog]
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]

    private var t: AppTheme { config.theme }
    private var waterToday: Double {
        waterLogs.filter { Calendar.current.isDateInToday($0.date) }.reduce(0) { $0 + $1.amountML }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Me").font(.serif(28)).foregroundStyle(t.ink).padding(.top, 4)

                    healthCard
                    waterCard
                    weightCard

                    NavigationLink {
                        SettingsView()
                    } label: {
                        HStack {
                            Label("Settings", systemImage: "gearshape.fill")
                                .font(.sans(14, .semibold)).foregroundStyle(t.ink)
                            Spacer()
                            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(t.ink2)
                        }
                        .glowCard(t, padding: 16, radius: 18)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(t.page.ignoresSafeArea())
            .navigationBarHidden(true)
            .task { if health.authorized { await health.refreshTodaySteps() } }
        }
    }

    private var healthCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple Health").sectionLabel().foregroundStyle(t.ink2)
            HStack {
                Text("👟 Steps today").font(.sans(13, .semibold)).foregroundStyle(t.ink)
                Spacer()
                Text("\(health.todaySteps)").font(.serif(22)).foregroundStyle(t.ink)
            }
            if !health.authorized {
                Button { Task { await health.requestAuthorization() } } label: {
                    Text("Connect Apple Health")
                        .font(.sans(13, .bold)).foregroundStyle(t.accentDeep)
                        .frame(maxWidth: .infinity).padding(11)
                        .background(t.accentSoft2, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowCard(t, padding: 16, radius: 20)
    }

    private var waterCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("💧 Water").font(.sans(13, .semibold)).foregroundStyle(t.ink)
                Spacer()
                Text("\(Int(waterToday)) / \(Int(config.waterGoalML)) ml")
                    .font(.sans(13, .semibold)).foregroundStyle(t.ink2)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(t.accentSoft2)
                    Capsule().fill(t.secondary)
                        .frame(width: geo.size.width * min(waterToday / max(config.waterGoalML, 1), 1))
                }
            }
            .frame(height: 10)
            HStack(spacing: 10) {
                quickWater("+250 ml", 250)
                quickWater("+500 ml", 500)
                Spacer()
                if waterToday > 0 {
                    Button { undoWater() } label: {
                        Text("Undo").font(.sans(12, .bold)).foregroundStyle(t.ink2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowCard(t, padding: 16, radius: 20)
    }

    private func quickWater(_ label: String, _ ml: Double) -> some View {
        Button { context.insert(WaterLog(date: Date(), amountML: ml)) } label: {
            Text(label).font(.sans(12, .bold)).foregroundStyle(t.accentDeep)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(t.accentSoft2, in: Capsule())
        }
    }

    private var weightCard: some View {
        NavigationLink {
            WeightView()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("⚖️ Body weight").font(.sans(13, .semibold)).foregroundStyle(t.ink)
                    Text("Log & trend").font(.sans(11, .medium)).foregroundStyle(t.ink2)
                }
                Spacer()
                if let latest = metrics.first {
                    Text(WeightFormat.display(latest.weightKg, metric: config.useMetric))
                        .font(.serif(20)).foregroundStyle(t.ink)
                }
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(t.ink2)
            }
            .glowCard(t, padding: 16, radius: 20)
        }
        .buttonStyle(.plain)
    }

    private func undoWater() {
        let todays = waterLogs.filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
        if let last = todays.last { context.delete(last) }
    }
}

/// kg <-> lb display helpers.
enum WeightFormat {
    static func display(_ kg: Double, metric: Bool) -> String {
        metric ? String(format: "%.1f kg", kg) : String(format: "%.1f lb", kg * 2.20462)
    }
    static func toKg(_ value: Double, metric: Bool) -> Double {
        metric ? value : value / 2.20462
    }
    static func fromKg(_ kg: Double, metric: Bool) -> Double {
        metric ? kg : kg * 2.20462
    }
}
