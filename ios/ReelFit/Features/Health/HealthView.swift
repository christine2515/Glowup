import SwiftUI
import SwiftData

/// "Me" tab: Apple Health steps, water, supplements, body weight, and settings.
struct HealthView: View {
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared
    @State private var health = HealthKitManager.shared

    @Query private var waterLogs: [WaterLog]
    @Query(sort: \Supplement.createdAt) private var supplements: [Supplement]
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]

    private var waterToday: Double {
        waterLogs.filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.amountML }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Apple Health") {
                    HStack {
                        Label("Steps today", systemImage: "shoeprints.fill")
                        Spacer()
                        Text("\(health.todaySteps)").bold().monospacedDigit()
                    }
                    if !health.authorized {
                        Button("Connect Apple Health") {
                            Task { await health.requestAuthorization() }
                        }
                    }
                }

                waterSection
                supplementsSection
                weightSection

                Section {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
            }
            .navigationTitle("Me")
            .task {
                if health.authorized { await health.refreshTodaySteps() }
            }
        }
    }

    // MARK: - Water

    private var waterSection: some View {
        Section("Water") {
            ProgressView(value: min(waterToday / max(config.waterGoalML, 1), 1)) {
                HStack {
                    Text("\(Int(waterToday)) / \(Int(config.waterGoalML)) ml")
                    Spacer()
                }
                .font(.subheadline)
            }
            HStack {
                Button("+250 ml") { addWater(250) }
                Button("+500 ml") { addWater(500) }
                Spacer()
                if waterToday > 0 {
                    Button(role: .destructive) { undoWater() } label: { Text("Undo") }
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private func addWater(_ ml: Double) {
        context.insert(WaterLog(date: Date(), amountML: ml))
    }

    private func undoWater() {
        let todays = waterLogs.filter { Calendar.current.isDateInToday($0.date) }
            .sorted { $0.date < $1.date }
        if let last = todays.last { context.delete(last) }
    }

    // MARK: - Supplements

    private var supplementsSection: some View {
        Section("Supplements") {
            if supplements.isEmpty {
                Text("Add supplements to track them daily.").foregroundStyle(.secondary)
            }
            ForEach(supplements) { supp in
                SupplementRow(supplement: supp)
            }
            NavigationLink {
                SupplementsManageView()
            } label: {
                Label("Manage supplements", systemImage: "pills")
            }
        }
    }

    // MARK: - Weight

    private var weightSection: some View {
        Section("Body weight") {
            if let latest = metrics.first {
                LabeledContent("Latest",
                               value: WeightFormat.display(latest.weightKg, metric: config.useMetric))
            }
            NavigationLink {
                WeightView()
            } label: {
                Label("Log & trend", systemImage: "scalemass")
            }
        }
    }
}

/// A supplement row with a per-day count toward its target.
struct SupplementRow: View {
    @Bindable var supplement: Supplement
    @Environment(\.modelContext) private var context

    private var todayCount: Int {
        (supplement.logs ?? []).filter { Calendar.current.isDateInToday($0.date) }.count
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(supplement.name)
                if !supplement.dose.isEmpty {
                    Text(supplement.dose).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(todayCount)/\(supplement.dailyTarget)")
                .monospacedDigit()
                .foregroundStyle(todayCount >= supplement.dailyTarget ? .green : .secondary)
            Button {
                let log = SupplementLog(date: Date())
                log.supplement = supplement
                context.insert(log)
            } label: {
                Image(systemName: "plus.circle.fill")
            }
            .buttonStyle(.plain)
            .disabled(todayCount >= supplement.dailyTarget)
        }
    }
}

/// kg <-> lb display helpers.
enum WeightFormat {
    static func display(_ kg: Double, metric: Bool) -> String {
        metric ? String(format: "%.1f kg", kg)
               : String(format: "%.1f lb", kg * 2.20462)
    }
    static func toKg(_ value: Double, metric: Bool) -> Double {
        metric ? value : value / 2.20462
    }
    static func fromKg(_ kg: Double, metric: Bool) -> Double {
        metric ? kg : kg * 2.20462
    }
}
