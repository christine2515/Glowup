import SwiftUI
import SwiftData

/// Training log. Phase 2 adds: log sessions by picking saved workouts, a run
/// planner, and progress charts (pull-ups / lifts / runs).
struct TrainView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "figure.run",
                        description: Text("Open a saved workout and tap “Log this workout” to start your history. Run planning and progress charts arrive in Phase 2.")
                    )
                } else {
                    List {
                        ForEach(sessions) { session in
                            VStack(alignment: .leading) {
                                Text(session.templateTitle.isEmpty ? "Workout" : session.templateTitle)
                                    .font(.headline)
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Train")
        }
    }
}
