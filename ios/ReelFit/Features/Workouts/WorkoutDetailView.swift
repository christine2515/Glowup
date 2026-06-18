import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Bindable var workout: WorkoutTemplate
    @Environment(\.modelContext) private var context
    @State private var loggedConfirmation = false
    @State private var editing = false

    var body: some View {
        List {
            if !workout.summary.isEmpty {
                Section { Text(workout.summary) }
            }

            Section("Moves") {
                ForEach(workout.sortedExercises) { ex in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(ex.name).font(.headline)
                            Spacer()
                            if let p = ex.prescription {
                                Text(p).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        if !ex.instructions.isEmpty {
                            Text(ex.instructions)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let eq = ex.equipment, !eq.isEmpty {
                            Label(eq, systemImage: "wrench.and.screwdriver")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if let link = URL(string: workout.sourceURL), !workout.sourceURL.isEmpty {
                Section {
                    Link(destination: link) {
                        Label("Open original reel in Instagram", systemImage: "play.rectangle")
                    }
                }
            }

            Section {
                Button {
                    logWorkout()
                } label: {
                    Label("Log this workout today", systemImage: "checkmark.circle")
                }
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Edit") { editing = true }
        }
        .sheet(isPresented: $editing) {
            EditWorkoutView(workout: workout)
        }
        .alert("Logged!", isPresented: $loggedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Added to today's training log.")
        }
    }

    private func logWorkout() {
        let session = WorkoutSession(date: Date(), templateTitle: workout.title)
        session.sourceTemplateID = workout.id
        for ex in workout.sortedExercises {
            let log = SetLog(
                exerciseName: ex.name,
                reps: ex.reps ?? 0,
                weight: 0,
                date: Date()
            )
            log.session = session
            context.insert(log)
        }
        context.insert(session)
        loggedConfirmation = true
    }
}
