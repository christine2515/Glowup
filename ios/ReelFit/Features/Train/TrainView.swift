import SwiftUI
import SwiftData

/// Training hub: log a session from a saved workout, review history, plan runs,
/// and view progress charts.
struct TrainView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var loggingSession = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        loggingSession = true
                    } label: {
                        Label("Log a workout", systemImage: "plus.circle.fill")
                    }
                    NavigationLink {
                        RunsView()
                    } label: {
                        Label("Runs & training plan", systemImage: "figure.run")
                    }
                    NavigationLink {
                        ProgressChartsView()
                    } label: {
                        Label("Progress charts", systemImage: "chart.xyaxis.line")
                    }
                }

                Section("History") {
                    if sessions.isEmpty {
                        Text("No sessions yet. Tap “Log a workout” to start.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(sessions) { session in
                        NavigationLink {
                            SessionDetailView(session: session)
                        } label: {
                            SessionRow(session: session)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
            .navigationTitle("Train")
            .sheet(isPresented: $loggingSession) {
                LogSessionView()
            }
        }
    }

    @Environment(\.modelContext) private var context

    private func deleteSessions(_ offsets: IndexSet) {
        for i in offsets { context.delete(sessions[i]) }
    }
}

private struct SessionRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(session.templateTitle.isEmpty ? "Workout" : session.templateTitle)
                .font(.headline)
            HStack(spacing: 8) {
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                let done = (session.setLogs ?? []).filter(\.done).count
                let total = (session.setLogs ?? []).count
                if total > 0 {
                    Text("· \(done)/\(total) sets")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
