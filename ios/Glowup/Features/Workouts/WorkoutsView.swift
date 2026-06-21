import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(PendingReels.self) private var pending
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var workouts: [WorkoutTemplate]

    @State private var importing: ImportTarget?
    private var t: AppTheme { config.theme }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    if !pending.reels.isEmpty { sharedSection }

                    if workouts.isEmpty && pending.reels.isEmpty { emptyState }

                    ForEach(WorkoutCategory.allCases) { category in
                        let items = workouts.filter { $0.category == category }
                        if !items.isEmpty { categorySection(category, items) }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .background(t.page.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(item: $importing) { ImportReelView(target: $0) }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Workouts").font(.serif(28)).foregroundStyle(t.ink)
            Spacer()
            Button { importing = .manual } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(t.accent, in: Circle())
                    .shadow(color: t.accentSoft, radius: 8, y: 6)
            }
        }
    }

    // MARK: - Shared from Instagram

    private var sharedSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                Image(systemName: "camera.aperture").foregroundStyle(t.accentDeep)
                Text("Shared from Instagram").sectionLabel().foregroundStyle(t.ink2)
                Spacer()
                Text("\(pending.reels.count)")
                    .font(.sans(11, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(t.accent, in: Capsule())
            }
            ForEach(pending.reels) { reel in
                Button { importing = .shared(reel) } label: {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(t.accentSoft2)
                            .frame(width: 54, height: 54)
                            .overlay(Image(systemName: "play.rectangle.fill").foregroundStyle(t.accent))
                        Text(reel.url).font(.sans(13, .semibold)).foregroundStyle(t.ink)
                            .lineLimit(2).multilineTextAlignment(.leading)
                        Spacer()
                        Text("Import")
                            .font(.sans(12, .bold)).foregroundStyle(.white)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .background(t.accent, in: Capsule())
                    }
                    .glowCard(t, padding: 10, radius: 18)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("🌸").font(.system(size: 30))
            Text("No reels yet").font(.serif(18)).foregroundStyle(t.ink)
            Text("Found a workout on Instagram? Tap **Share → Glowup** and we'll save the moves for you.")
                .font(.sans(13, .medium)).foregroundStyle(t.ink2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glowCard(t, padding: 24, radius: 20)
        .padding(.top, 6)
    }

    // MARK: - Category section

    private func categorySection(_ category: WorkoutCategory, _ items: [WorkoutTemplate]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(category.title).sectionLabel().foregroundStyle(t.ink2)
                .padding(.leading, 2)
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, workout in
                    NavigationLink {
                        WorkoutDetailView(workout: workout)
                    } label: {
                        workoutRow(workout)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) { context.delete(workout) } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    if idx < items.count - 1 {
                        Divider().overlay(t.ring).padding(.leading, 16)
                    }
                }
            }
            .background(t.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color(hex: "46503C").opacity(0.05), radius: 9, y: 3)
        }
    }

    private func workoutRow(_ workout: WorkoutTemplate) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title).font(.sans(14, .semibold)).foregroundStyle(t.ink)
                Text(subtitle(workout)).font(.sans(11, .medium)).foregroundStyle(t.ink2)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(t.ink2)
        }
        .padding(14)
        .contentShape(Rectangle())
    }

    private func subtitle(_ w: WorkoutTemplate) -> String {
        let n = w.sortedExercises.count
        let equip = w.sortedExercises.compactMap { $0.equipment }.first
        return equip.map { "\($0) · \(n) moves" } ?? "\(n) moves"
    }
}

/// What the import sheet is working on.
enum ImportTarget: Identifiable {
    case manual
    case shared(SharedReel)

    var id: String {
        switch self {
        case .manual: "manual"
        case .shared(let r): r.id.uuidString
        }
    }

    var prefilledURL: String {
        switch self {
        case .manual: ""
        case .shared(let r): r.url
        }
    }

    var sharedReel: SharedReel? {
        if case .shared(let r) = self { return r }
        return nil
    }
}
