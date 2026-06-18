import SwiftUI
import SwiftData

/// Edit a previously logged session.
struct SessionDetailView: View {
    @Bindable var session: WorkoutSession
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared

    private var sortedLogs: [SetLog] {
        (session.setLogs ?? []).sorted { $0.order < $1.order }
    }

    var body: some View {
        Form {
            Section("Sets") {
                ForEach(sortedLogs) { log in
                    PersistedSetRow(log: log, unit: config.useMetric ? "kg" : "lb")
                }
                .onDelete(perform: deleteLogs)

                Button {
                    addSet()
                } label: {
                    Label("Add set", systemImage: "plus")
                }
            }

            Section("How it went") {
                Stepper("Effort (RPE): \(session.effort ?? 0)",
                        value: Binding(
                            get: { session.effort ?? 7 },
                            set: { session.effort = $0 }
                        ), in: 1...10)
                TextField("Notes", text: $session.notes, axis: .vertical)
            }
        }
        .navigationTitle(session.templateTitle.isEmpty ? "Session" : session.templateTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }

    private func addSet() {
        let log = SetLog(exerciseName: sortedLogs.last?.exerciseName ?? "", reps: 0, weight: 0)
        log.order = (sortedLogs.last?.order ?? -1) + 1
        log.date = session.date
        log.session = session
        context.insert(log)
    }

    private func deleteLogs(_ offsets: IndexSet) {
        let logs = sortedLogs
        for i in offsets { context.delete(logs[i]) }
    }
}

private struct PersistedSetRow: View {
    @Bindable var log: SetLog
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Exercise", text: $log.exerciseName)
                .font(.subheadline.weight(.semibold))
            HStack {
                Stepper("Reps: \(log.reps)", value: $log.reps, in: 0...100)
                    .fixedSize()
                Spacer()
                Toggle("", isOn: $log.done)
                    .labelsHidden()
                    .toggleStyle(.button)
                    .tint(.green)
            }
            HStack {
                Text("Weight")
                TextField("0", value: $log.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text(unit).foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}
