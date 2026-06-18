import Foundation
import SwiftData

enum WorkoutCategory: String, Codable, CaseIterable, Identifiable {
    case arms, abs, legs, fullBody, cardio, mobility, other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .arms: "Arms"
        case .abs: "Abs"
        case .legs: "Legs"
        case .fullBody: "Full Body"
        case .cardio: "Cardio"
        case .mobility: "Mobility"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .arms: "dumbbell"
        case .abs: "figure.core.training"
        case .legs: "figure.run"
        case .fullBody: "figure.strengthtraining.functional"
        case .cardio: "heart.fill"
        case .mobility: "figure.flexibility"
        case .other: "star"
        }
    }
}

/// A saved workout, usually imported from an Instagram reel.
@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var title: String = ""
    var categoryRaw: String = WorkoutCategory.other.rawValue
    var summary: String = ""
    var sourceURL: String = ""        // the Instagram reel link
    var thumbnailURL: String?
    var caption: String = ""
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Exercise.template)
    var exercises: [Exercise]? = []

    init(
        title: String = "",
        category: WorkoutCategory = .other,
        summary: String = "",
        sourceURL: String = "",
        thumbnailURL: String? = nil,
        caption: String = "",
        createdAt: Date = Date()
    ) {
        self.title = title
        self.categoryRaw = category.rawValue
        self.summary = summary
        self.sourceURL = sourceURL
        self.thumbnailURL = thumbnailURL
        self.caption = caption
        self.createdAt = createdAt
    }

    var category: WorkoutCategory {
        get { WorkoutCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var sortedExercises: [Exercise] {
        (exercises ?? []).sorted { $0.order < $1.order }
    }
}

@Model
final class Exercise {
    var name: String = ""
    var instructions: String = ""
    var sets: Int?
    var reps: Int?
    var durationSec: Int?
    var restSec: Int?
    var equipment: String?
    var order: Int = 0

    var template: WorkoutTemplate?

    init(
        name: String = "",
        instructions: String = "",
        sets: Int? = nil,
        reps: Int? = nil,
        durationSec: Int? = nil,
        restSec: Int? = nil,
        equipment: String? = nil,
        order: Int = 0
    ) {
        self.name = name
        self.instructions = instructions
        self.sets = sets
        self.reps = reps
        self.durationSec = durationSec
        self.restSec = restSec
        self.equipment = equipment
        self.order = order
    }

    /// e.g. "3 × 12" or "30s"
    var prescription: String? {
        if let s = sets, let r = reps { return "\(s) × \(r)" }
        if let r = reps { return "\(r) reps" }
        if let d = durationSec { return "\(d)s" }
        return nil
    }
}

/// A logged workout on a given day (Phase 2 wires the full UI).
@Model
final class WorkoutSession {
    var date: Date = Date()
    var templateTitle: String = ""    // denormalized for display
    var sourceTemplateID: UUID?
    var durationMin: Int?
    var effort: Int?                  // 1–10 RPE
    var notes: String = ""

    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var setLogs: [SetLog]? = []

    init(date: Date = Date(), templateTitle: String = "") {
        self.date = date
        self.templateTitle = templateTitle
    }
}

@Model
final class SetLog {
    var exerciseName: String = ""
    var reps: Int = 0
    var weight: Double = 0            // kg/lb per user preference; stored as entered
    var done: Bool = false
    var order: Int = 0
    var date: Date = Date()           // duplicated for cross-session progress queries

    var session: WorkoutSession?

    init(exerciseName: String = "", reps: Int = 0, weight: Double = 0, date: Date = Date()) {
        self.exerciseName = exerciseName
        self.reps = reps
        self.weight = weight
        self.date = date
    }
}

enum RunSource: String, Codable {
    case manual, strava
}

/// Planned or completed run for training. Runs imported from Strava use
/// `source == .strava` and carry the Strava activity id in `externalID`.
@Model
final class RunEntry {
    var date: Date = Date()
    var plannedDistanceKm: Double = 0
    var actualDistanceKm: Double?
    var actualDurationMin: Double?
    var notes: String = ""
    var completed: Bool = false
    var name: String = ""
    var sourceRaw: String = RunSource.manual.rawValue
    var externalID: String?

    init(date: Date = Date(), plannedDistanceKm: Double = 0) {
        self.date = date
        self.plannedDistanceKm = plannedDistanceKm
    }

    var source: RunSource {
        get { RunSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    /// min/km, when completed.
    var pace: Double? {
        guard let d = actualDistanceKm, let t = actualDurationMin, d > 0 else { return nil }
        return t / d
    }
}
