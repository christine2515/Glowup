import SwiftUI
import SwiftData
import Charts

/// Progress over time: per-exercise best set (great for pull-ups / lifts) and
/// run distance.
struct ProgressChartsView: View {
    @Query private var logs: [SetLog]
    @Query private var runs: [RunEntry]

    @State private var selectedExercise: String = ""

    private var exerciseNames: [String] {
        Array(Set(logs.map(\.exerciseName)))
            .filter { !$0.isEmpty }
            .sorted()
    }

    /// Best set per day for the selected exercise. Uses weight when any set has
    /// weight; otherwise reps (so bodyweight moves like pull-ups still chart).
    private var exercisePoints: [DataPoint] {
        let matching = logs.filter { $0.exerciseName == selectedExercise }
        guard !matching.isEmpty else { return [] }
        let usesWeight = matching.contains { $0.weight > 0 }
        let byDay = Dictionary(grouping: matching) {
            Calendar.current.startOfDay(for: $0.date)
        }
        return byDay.map { day, sets in
            let value = usesWeight ? (sets.map(\.weight).max() ?? 0)
                                   : Double(sets.map(\.reps).max() ?? 0)
            return DataPoint(date: day, value: value)
        }
        .sorted { $0.date < $1.date }
    }

    private var exerciseUsesWeight: Bool {
        logs.filter { $0.exerciseName == selectedExercise }.contains { $0.weight > 0 }
    }

    private var runPoints: [DataPoint] {
        runs.filter(\.completed)
            .compactMap { r in r.actualDistanceKm.map { DataPoint(date: r.date, value: $0) } }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            Section("Exercise progress") {
                if exerciseNames.isEmpty {
                    Text("Log some sets to see progress.").foregroundStyle(.secondary)
                } else {
                    Picker("Exercise", selection: $selectedExercise) {
                        ForEach(exerciseNames, id: \.self) { Text($0).tag($0) }
                    }
                    if exercisePoints.count >= 1 {
                        Chart(exercisePoints) { point in
                            LineMark(x: .value("Date", point.date),
                                     y: .value(exerciseUsesWeight ? "Weight" : "Reps", point.value))
                            PointMark(x: .value("Date", point.date),
                                      y: .value("Value", point.value))
                        }
                        .frame(height: 200)
                        Text(exerciseUsesWeight ? "Top weight per day" : "Top reps per day")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("No data for this exercise yet.").foregroundStyle(.secondary)
                    }
                }
            }

            Section("Runs") {
                if runPoints.isEmpty {
                    Text("Log a run to see your distance trend.").foregroundStyle(.secondary)
                } else {
                    Chart(runPoints) { point in
                        BarMark(x: .value("Date", point.date),
                                y: .value("km", point.value))
                    }
                    .frame(height: 200)
                    Text("Distance per run (km)").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Progress")
        .onAppear {
            if selectedExercise.isEmpty { selectedExercise = exerciseNames.first ?? "" }
        }
    }
}

private struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
