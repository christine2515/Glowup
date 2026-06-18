import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(PendingReels.self) private var pending
    @Query(sort: \WorkoutTemplate.createdAt, order: .reverse)
    private var workouts: [WorkoutTemplate]

    @State private var importing: ImportTarget?

    var body: some View {
        NavigationStack {
            List {
                if !pending.reels.isEmpty {
                    Section("Shared from Instagram") {
                        ForEach(pending.reels) { reel in
                            Button {
                                importing = .shared(reel)
                            } label: {
                                Label(reel.url, systemImage: "arrow.down.circle")
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                if workouts.isEmpty && pending.reels.isEmpty {
                    ContentUnavailableView(
                        "No workouts yet",
                        systemImage: "dumbbell",
                        description: Text("Share an Instagram reel to ReelFit, or tap + to add one.")
                    )
                }

                ForEach(WorkoutCategory.allCases) { category in
                    let items = workouts.filter { $0.category == category }
                    if !items.isEmpty {
                        Section(category.title) {
                            ForEach(items) { workout in
                                NavigationLink {
                                    WorkoutDetailView(workout: workout)
                                } label: {
                                    WorkoutRow(workout: workout)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                Button {
                    importing = .manual
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(item: $importing) { target in
                ImportReelView(target: target)
            }
        }
    }
}

private struct WorkoutRow: View {
    let workout: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.title).font(.headline)
            Text("\(workout.sortedExercises.count) moves")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
