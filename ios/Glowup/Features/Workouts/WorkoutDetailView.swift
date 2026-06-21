import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Bindable var workout: WorkoutTemplate
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared
    @State private var loggedConfirmation = false
    @State private var editing = false

    private var t: AppTheme { config.theme }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(workout.category.title.uppercased())
                    .font(.sans(11, .bold)).kerning(0.5)
                    .foregroundStyle(t.accentDeep)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(t.accentSoft, in: Capsule())

                Text(workout.title)
                    .font(.serif(27)).foregroundStyle(t.ink)
                    .padding(.top, 11)

                if !workout.summary.isEmpty {
                    Text(workout.summary)
                        .font(.sans(13, .medium)).foregroundStyle(t.ink2)
                        .padding(.top, 8)
                }

                if let link = URL(string: workout.sourceURL), !workout.sourceURL.isEmpty {
                    Link(destination: link) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.aperture")
                            Text("Open original reel in Instagram")
                                .underline()
                        }
                        .font(.sans(13, .bold)).foregroundStyle(t.accentDeep)
                    }
                    .padding(.top, 14)
                }

                Text("\(workout.sortedExercises.count) moves").sectionLabel()
                    .foregroundStyle(t.ink2)
                    .padding(.top, 20).padding(.bottom, 10)

                ForEach(Array(workout.sortedExercises.enumerated()), id: \.element.id) { i, ex in
                    moveCard(index: i + 1, ex: ex).padding(.bottom, 10)
                }

                VStack(spacing: 10) {
                    Button { logWorkout() } label: {
                        Label("Log this workout today", systemImage: "checkmark.circle.fill")
                            .font(.sans(15, .bold)).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(15)
                            .background(t.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: t.accentSoft, radius: 10, y: 6)
                    }
                    Button { editing = true } label: {
                        Text("Edit workout")
                            .font(.sans(14, .bold)).foregroundStyle(t.accentDeep)
                            .frame(maxWidth: .infinity).padding(14)
                            .background(t.accentSoft2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(t.page.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { editing = true }
                    .font(.sans(13, .bold)).foregroundStyle(t.accentDeep)
            }
        }
        .sheet(isPresented: $editing) { EditWorkoutView(workout: workout) }
        .alert("Logged!", isPresented: $loggedConfirmation) {
            Button("OK", role: .cancel) {}
        } message: { Text("Added to today's training log.") }
    }

    private func moveCard(index: Int, ex: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(index) · \(ex.name)").font(.sans(14, .bold)).foregroundStyle(t.ink)
                Spacer()
                if let p = ex.prescription {
                    Text(p).font(.sans(12, .bold)).foregroundStyle(t.accentDeep)
                }
            }
            if !ex.instructions.isEmpty {
                Text(ex.instructions).font(.sans(12, .medium)).foregroundStyle(t.ink2)
            }
            if let eq = ex.equipment, !eq.isEmpty {
                Label(eq, systemImage: "dumbbell").font(.sans(11, .medium)).foregroundStyle(t.ink2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowCard(t, padding: 15, radius: 18)
    }

    private func logWorkout() {
        let session = WorkoutSession(date: Date(), templateTitle: workout.title)
        session.sourceTemplateID = workout.id
        for ex in workout.sortedExercises {
            let log = SetLog(exerciseName: ex.name, reps: ex.reps ?? 0, weight: 0, date: Date())
            log.session = session
            context.insert(log)
        }
        context.insert(session)
        loggedConfirmation = true
    }
}
