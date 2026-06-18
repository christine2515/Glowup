import SwiftUI
import SwiftData

/// Edit an imported workout: name, description, category, reel link, and the
/// list of moves (add / delete / reorder, with per-move detail editing).
struct EditWorkoutView: View {
    @Bindable var workout: WorkoutTemplate
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private var sortedExercises: [Exercise] {
        (workout.exercises ?? []).sorted { $0.order < $1.order }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout") {
                    TextField("Title", text: $workout.title)
                    Picker("Category", selection: Binding(
                        get: { workout.category },
                        set: { workout.category = $0 }
                    )) {
                        ForEach(WorkoutCategory.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Description", text: $workout.summary, axis: .vertical)
                        .lineLimit(2...6)
                }

                Section {
                    TextField("https://www.instagram.com/reel/…", text: $workout.sourceURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                } header: {
                    Text("Reel link")
                } footer: {
                    Text("Paste the Instagram reel link so you can open it later from the workout detail screen.")
                }

                Section("Moves") {
                    ForEach(sortedExercises) { exercise in
                        NavigationLink {
                            ExerciseEditView(exercise: exercise)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(exercise.name.isEmpty ? "Untitled move" : exercise.name)
                                if let p = exercise.prescription {
                                    Text(p).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteMoves)
                    .onMove(perform: moveMoves)

                    Button {
                        addMove()
                    } label: {
                        Label("Add move", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    private func addMove() {
        let move = Exercise(name: "", order: (sortedExercises.last?.order ?? -1) + 1)
        move.template = workout
        context.insert(move)
    }

    private func deleteMoves(_ offsets: IndexSet) {
        let list = sortedExercises
        for i in offsets { context.delete(list[i]) }
    }

    private func moveMoves(_ offsets: IndexSet, _ destination: Int) {
        var list = sortedExercises
        list.move(fromOffsets: offsets, toOffset: destination)
        for (i, move) in list.enumerated() { move.order = i }
    }
}

/// Edit a single move's details.
struct ExerciseEditView: View {
    @Bindable var exercise: Exercise

    var body: some View {
        Form {
            Section("Move") {
                TextField("Name", text: $exercise.name)
            }
            Section("How to do it") {
                TextField("Instructions", text: $exercise.instructions, axis: .vertical)
                    .lineLimit(3...10)
            }
            Section("Prescription") {
                optionalStepper("Sets / rounds", value: $exercise.sets, range: 0...20)
                optionalStepper("Reps", value: $exercise.reps, range: 0...200)
                optionalStepper("Duration (sec)", value: $exercise.durationSec, range: 0...3600, step: 5)
                optionalStepper("Rest (sec)", value: $exercise.restSec, range: 0...600, step: 5)
            }
            Section("Equipment") {
                TextField("e.g. dumbbells (optional)",
                          text: Binding(
                            get: { exercise.equipment ?? "" },
                            set: { exercise.equipment = $0.isEmpty ? nil : $0 }
                          ))
            }
        }
        .navigationTitle(exercise.name.isEmpty ? "Move" : exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Stepper over an optional Int where 0 means "unspecified" (stored as nil).
    private func optionalStepper(_ label: String, value: Binding<Int?>, range: ClosedRange<Int>, step: Int = 1) -> some View {
        let proxy = Binding<Int>(
            get: { value.wrappedValue ?? 0 },
            set: { value.wrappedValue = $0 == 0 ? nil : $0 }
        )
        return Stepper(value: proxy, in: range, step: step) {
            HStack {
                Text(label)
                Spacer()
                Text(proxy.wrappedValue == 0 ? "—" : "\(proxy.wrappedValue)")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
