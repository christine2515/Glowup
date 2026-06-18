import SwiftUI
import SwiftData

/// Dashboard. Phase 4 wires this to live macro rings, water, supplements,
/// steps, and the weight trend. Phase 0 shows today's logged workout count.
struct TodayView: View {
    @Query private var sessions: [WorkoutSession]
    @State private var health = HealthKitManager.shared

    private var todaySessions: [WorkoutSession] {
        sessions.filter { Calendar.current.isDateInToday($0.date) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Today") {
                    LabeledContent("Workouts logged", value: "\(todaySessions.count)")
                    LabeledContent("Steps", value: "\(health.todaySteps)")
                }
                ForEach(todaySessions) { session in
                    LabeledContent(session.templateTitle.isEmpty ? "Workout" : session.templateTitle,
                                   value: session.date.formatted(date: .omitted, time: .shortened))
                }
            }
            .navigationTitle("Today")
            .task {
                if health.authorized { await health.refreshTodaySteps() }
            }
        }
    }
}
