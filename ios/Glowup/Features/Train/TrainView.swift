import SwiftUI
import SwiftData

/// Training hub: log a session, plan runs, view progress & calendar.
struct TrainView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var config = AppConfig.shared
    @State private var loggingSession = false
    private var t: AppTheme { config.theme }

    private let cols = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Train").font(.serif(28)).foregroundStyle(t.ink)
                        .padding(.top, 4)

                    LazyVGrid(columns: cols, spacing: 12) {
                        Button { loggingSession = true } label: {
                            actionCard("📝", "Log a workout", "Sets, reps & RPE", t.accentSoft)
                        }.buttonStyle(.plain)
                        NavigationLink { RunsView() } label: {
                            actionCard("🏃‍♀️", "Runs & plan", "Synced from Strava", t.secondarySoft)
                        }.buttonStyle(.plain)
                        NavigationLink { ProgressChartsView() } label: {
                            actionCard("📈", "Progress charts", "Strength & reps", t.accentSoft)
                        }.buttonStyle(.plain)
                        NavigationLink { CalendarHeatmapView() } label: {
                            actionCard("🗓️", "Workout calendar", "Year heatmap", t.secondarySoft)
                        }.buttonStyle(.plain)
                    }

                    Text("Recent sessions").sectionLabel().foregroundStyle(t.ink2)
                        .padding(.leading, 2).padding(.top, 4)

                    if sessions.isEmpty {
                        Text("No sessions yet. Tap “Log a workout” to start.")
                            .font(.sans(13, .medium)).foregroundStyle(t.ink2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glowCard(t, padding: 16, radius: 18)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(sessions.prefix(8).enumerated()), id: \.element.id) { idx, session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: { sessionRow(session) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) { context.delete(session) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                if idx < min(sessions.count, 8) - 1 {
                                    Divider().overlay(t.ring).padding(.leading, 16)
                                }
                            }
                        }
                        .background(t.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: Color(hex: "46503C").opacity(0.05), radius: 9, y: 3)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(t.page.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $loggingSession) { LogSessionView() }
        }
    }

    private func actionCard(_ emoji: String, _ title: String, _ sub: String, _ iconBg: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(emoji).font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(iconBg, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .padding(.bottom, 7)
            Text(title).font(.sans(14, .bold)).foregroundStyle(t.ink)
            Text(sub).font(.sans(11, .medium)).foregroundStyle(t.ink2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glowCard(t, padding: 16, radius: 20)
    }

    private func sessionRow(_ session: WorkoutSession) -> some View {
        let done = (session.setLogs ?? []).filter(\.done).count
        let total = (session.setLogs ?? []).count
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.templateTitle.isEmpty ? "Workout" : session.templateTitle)
                    .font(.sans(14, .semibold)).foregroundStyle(t.ink)
                Text(relativeDay(session.date) + (total > 0 ? " · \(total) sets" : ""))
                    .font(.sans(11, .medium)).foregroundStyle(t.ink2)
            }
            Spacer()
            if let rpe = session.effort {
                Text("RPE \(rpe)")
                    .font(.sans(11, .bold)).foregroundStyle(t.accentDeep)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(t.accentSoft, in: Capsule())
            } else if done == total && total > 0 {
                Text("Done").font(.sans(11, .bold)).foregroundStyle(t.accentDeep)
                    .padding(.horizontal, 9).padding(.vertical, 3)
                    .background(t.accentSoft, in: Capsule())
            }
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private func relativeDay(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        return date.formatted(.dateTime.weekday(.abbreviated))
    }
}
