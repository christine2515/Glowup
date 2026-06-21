import SwiftUI
import SwiftData
import Charts

/// Log body weight and see the trend.
struct WeightView: View {
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]

    @State private var newWeight = 0.0

    private var chartData: [BodyMetric] {
        metrics.sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            Section("Units") {
                Picker("Units", selection: $config.useMetric) {
                    Text("kg").tag(true)
                    Text("lb").tag(false)
                }
                .pickerStyle(.segmented)
            }

            Section("Log weight") {
                HStack {
                    TextField("0", value: $newWeight, format: .number)
                        .keyboardType(.decimalPad)
                    Text(config.useMetric ? "kg" : "lb").foregroundStyle(.secondary)
                    Button("Add") { addWeight() }
                        .buttonStyle(.borderedProminent)
                        .disabled(newWeight <= 0)
                }
            }

            if chartData.count >= 2 {
                Section("Trend") {
                    Chart(chartData) { m in
                        LineMark(
                            x: .value("Date", m.date),
                            y: .value("Weight", WeightFormat.fromKg(m.weightKg, metric: config.useMetric))
                        )
                        PointMark(
                            x: .value("Date", m.date),
                            y: .value("Weight", WeightFormat.fromKg(m.weightKg, metric: config.useMetric))
                        )
                    }
                    .frame(height: 220)
                }
            }

            Section("History") {
                if metrics.isEmpty {
                    Text("No entries yet.").foregroundStyle(.secondary)
                }
                ForEach(metrics) { m in
                    LabeledContent(
                        m.date.formatted(date: .abbreviated, time: .omitted),
                        value: WeightFormat.display(m.weightKg, metric: config.useMetric)
                    )
                }
                .onDelete { offsets in
                    for i in offsets { context.delete(metrics[i]) }
                }
            }
        }
        .navigationTitle("Body Weight")
        .navigationBarTitleDisplayMode(.inline)
        .airyBackground(config.theme)
    }

    private func addWeight() {
        let kg = WeightFormat.toKg(newWeight, metric: config.useMetric)
        context.insert(BodyMetric(date: Date(), weightKg: kg))
        newWeight = 0
    }
}
