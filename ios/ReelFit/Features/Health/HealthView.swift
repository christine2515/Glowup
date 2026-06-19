import SwiftUI
import SwiftData

/// "Me" tab: Apple Health steps, water, body weight, and settings.
struct HealthView: View {
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared
    @State private var health = HealthKitManager.shared

    @Query private var waterLogs: [WaterLog]
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
            .airyBackground(config.theme)
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
