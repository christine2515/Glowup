import SwiftUI
import SwiftData

/// Sheet to log a new session: pick a saved workout (or start empty), then
/// edit the sets you actually did before saving.
struct LogSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var config = AppConfig.shared

    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var templates: [WorkoutTemplate]

    @State private var selected: WorkoutTemplate?
    @State private var startedEmpty = false
    @State private var rows: [EditableSet] = []
    @State private var notes = ""
    @State private var effort = 7

    private var isEditing: Bool { selected != nil || startedEmpty }

    var body: some View {
        NavigationStack {
            Group {
                if isEditing {
                    editor
                } else {
                    picker
                }
            }
            .navigationTitle(isEditing ? "Log Session" : "Choose Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if isEditing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }.disabled(rows.isEmpty)
                    }
                }
            }
        }
    }

    // MARK: - Picker step

    private var picker: some View {
        List {
            Section {
                Button {
                    startedEmpty = true
                    rows = [EditableSet(exerciseName: "")]
                } label: {
                    Label("Empty session", systemImage: "square.dashed")
                }
            }
            Section("From your library") {
                if templates.isEmpty {
                    Text("Import a workout first (Workouts tab).")
                        .foregroundStyle(.secondary)
                }
                ForEach(templates) { template in
                    Button {
                        start(with: template)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(template.title).font(.headline)
                            Text("\(template.sortedExercises.count) moves · \(template.category.title)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Editor step

    private var editor: some View {
        Form {
            Section("Sets") {
                ForEach($rows) { $row in
                    SetEditorRow(row: $row, unit: config.useMetric ? "kg" : "lb")
                }
                .onDelete { rows.remove(atOffsets: $0) }

                Button {
                    rows.append(EditableSet(exerciseName: rows.last?.exerciseName ?? ""))
                } label: {
                    Label("Add set", systemImage: "plus")
                }
            }
            Section("How it went") {
                Stepper("Effort (RPE): \(effort)", value: $effort, in: 1...10)
                TextField("Notes", text: $notes, axis: .vertical)
            }
        }
    }

    // MARK: - Actions

    private func start(with template: WorkoutTemplate) {
        selected = template
        rows = template.sortedExercises.map {
            EditableSet(exerciseName: $0.name, reps: $0.reps ?? 0)
        }
        if rows.isEmpty { rows = [EditableSet(exerciseName: "")] }
    }

    private func save() {
        let session = WorkoutSession(date: Date(), templateTitle: selected?.title ?? "Workout")
        session.sourceTemplateID = selected?.id
        session.effort = effort
        session.notes = notes
        context.insert(session)
        for (i, row) in rows.enumerated() where !row.exerciseName.trimmingCharacters(in: .whitespaces).isEmpty {
            let log = SetLog(exerciseName: row.exerciseName, reps: row.reps, weight: row.weight)
            log.done = row.done
            log.order = i
            log.session = session
            context.insert(log)
        }
        dismiss()
    }
}

/// In-memory editable set used before persisting a new session.
struct EditableSet: Identifiable {
    let id = UUID()
    var exerciseName: String
    var reps: Int = 0
    var weight: Double = 0
    var done: Bool = false
}

struct SetEditorRow: View {
    @Binding var row: EditableSet
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Exercise", text: $row.exerciseName)
                .font(.subheadline.weight(.semibold))
            HStack {
                Stepper("Reps: \(row.reps)", value: $row.reps, in: 0...100)
                    .fixedSize()
                Spacer()
                Toggle("", isOn: $row.done)
                    .labelsHidden()
                    .toggleStyle(.button)
                    .tint(.green)
            }
            HStack {
                Text("Weight")
                TextField("0", value: $row.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                Text(unit).foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
        .padding(.vertical, 2)
    }
}
