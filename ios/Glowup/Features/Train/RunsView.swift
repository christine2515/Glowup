import SwiftUI
import SwiftData

/// Plan runs for training and log completed runs (distance, time → pace).
struct RunsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \RunEntry.date) private var runs: [RunEntry]

    @State private var addingRun = false
    @State private var completing: RunEntry?
    @State private var strava = StravaService.shared
    @State private var syncing = false
    @State private var errorText: String?

    private var upcoming: [RunEntry] {
        runs.filter { !$0.completed }.sorted { $0.date < $1.date }
    }
    private var completed: [RunEntry] {
        runs.filter { $0.completed }.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section("Strava") {
                if strava.isConnected {
                    Button {
                        Task { await sync() }
                    } label: {
                        if syncing { HStack { ProgressView(); Text("Syncing…") } }
                        else { Label("Sync runs from Strava", systemImage: "arrow.triangle.2.circlepath") }
                    }
                    .disabled(syncing)
                    Button("Disconnect Strava", role: .destructive) { strava.disconnect() }
                } else {
                    Button {
                        Task { await connect() }
                    } label: {
                        Label("Connect Strava", systemImage: "link")
                    }
                }
                if let msg = strava.lastSyncMessage {
                    Text(msg).font(.caption).foregroundStyle(.secondary)
                }
                if let errorText {
                    Text(errorText).font(.caption).foregroundStyle(.red)
                }
            }

            Section("Planned") {
                if upcoming.isEmpty {
                    Text("No runs planned.").foregroundStyle(.secondary)
                }
                ForEach(upcoming) { run in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(run.plannedDistanceKm, specifier: "%.1f") km")
                                .font(.headline)
                            Text(run.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Log") { completing = run }
                            .buttonStyle(.borderedProminent)
                    }
                }
                .onDelete { delete(upcoming, $0) }
            }

            Section("Completed") {
                if completed.isEmpty {
                    Text("No runs logged yet.").foregroundStyle(.secondary)
                }
                ForEach(completed) { run in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("\(run.actualDistanceKm ?? 0, specifier: "%.1f") km")
                                .font(.headline)
                            if run.source == .strava {
                                Text("Strava")
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        if !run.name.isEmpty {
                            Text(run.name).font(.subheadline)
                        }
                        HStack {
                            Text(run.date.formatted(date: .abbreviated, time: .omitted))
                            if let pace = run.pace {
                                Text("· \(paceString(pace))/km")
                            }
                        }
                        .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { delete(completed, $0) }
            }
        }
        .navigationTitle("Runs")
        .airyBackground(AppConfig.shared.theme)
        .toolbar {
            Button { addingRun = true } label: { Image(systemName: "plus") }
        }
        .sheet(isPresented: $addingRun) { PlanRunSheet() }
        .sheet(item: $completing) { run in LogRunSheet(run: run) }
    }

    private func delete(_ list: [RunEntry], _ offsets: IndexSet) {
        for i in offsets { context.delete(list[i]) }
    }

    private func connect() async {
        errorText = nil
        do {
            try await strava.connect()
            await sync()
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func sync() async {
        errorText = nil
        syncing = true
        defer { syncing = false }
        do {
            try await strava.syncRuns(into: context)
        } catch {
            errorText = error.localizedDescription
        }
    }
}

func paceString(_ minPerKm: Double) -> String {
    let m = Int(minPerKm)
    let s = Int((minPerKm - Double(m)) * 60)
    return String(format: "%d:%02d", m, s)
}

private struct PlanRunSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()
    @State private var distance = 5.0

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Stepper("Distance: \(distance, specifier: "%.1f") km", value: $distance, in: 0.5...60, step: 0.5)
            }
            .navigationTitle("Plan a Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let run = RunEntry(date: date, plannedDistanceKm: distance)
                        context.insert(run)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct LogRunSheet: View {
    @Bindable var run: RunEntry
    @Environment(\.dismiss) private var dismiss
    @State private var distance: Double
    @State private var minutes: Double

    init(run: RunEntry) {
        self.run = run
        _distance = State(initialValue: run.actualDistanceKm ?? run.plannedDistanceKm)
        _minutes = State(initialValue: run.actualDurationMin ?? 0)
    }

    var body: some View {
        NavigationStack {
            Form {
                Stepper("Distance: \(distance, specifier: "%.1f") km", value: $distance, in: 0.1...60, step: 0.1)
                HStack {
                    Text("Time (min)")
                    TextField("0", value: $minutes, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                if distance > 0 && minutes > 0 {
                    LabeledContent("Pace", value: "\(paceString(minutes / distance))/km")
                }
            }
            .navigationTitle("Log Run")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        run.actualDistanceKm = distance
                        run.actualDurationMin = minutes
                        run.completed = true
                        dismiss()
                    }
                }
            }
        }
    }
}
