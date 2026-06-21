import Foundation
import SwiftData

/// A body-weight (or body-fat) measurement for the weight-loss trend.
@Model
final class BodyMetric {
    var date: Date = Date()
    var weightKg: Double = 0
    var bodyFatPct: Double?

    init(date: Date = Date(), weightKg: Double = 0, bodyFatPct: Double? = nil) {
        self.date = date
        self.weightKg = weightKg
        self.bodyFatPct = bodyFatPct
    }
}

/// One water-intake entry (ml).
@Model
final class WaterLog {
    var date: Date = Date()
    var amountML: Double = 0

    init(date: Date = Date(), amountML: Double = 0) {
        self.date = date
        self.amountML = amountML
    }
}

/// One protein-intake entry (grams).
@Model
final class ProteinLog {
    var date: Date = Date()
    var grams: Double = 0

    init(date: Date = Date(), grams: Double = 0) {
        self.date = date
        self.grams = grams
    }
}

/// A user-configured supplement to track daily (e.g. fiber, collagen, vitamin D).
@Model
final class Supplement {
    var name: String = ""
    var emoji: String = "💊"
    var dose: String = ""          // optional, e.g. "5 g" / "1000 IU"
    var dailyTarget: Int = 1       // how many times per day
    var order: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \SupplementLog.supplement)
    var logs: [SupplementLog]? = []

    init(name: String = "", emoji: String = "💊", dose: String = "", dailyTarget: Int = 1, order: Int = 0) {
        self.name = name
        self.emoji = emoji
        self.dose = dose
        self.dailyTarget = dailyTarget
        self.order = order
    }

    func takenCount(on date: Date = Date()) -> Int {
        (logs ?? []).filter { Calendar.current.isDate($0.date, inSameDayAs: date) }.count
    }
}

/// A single "took it" entry for a supplement on a day.
@Model
final class SupplementLog {
    var date: Date = Date()
    var supplement: Supplement?

    init(date: Date = Date()) {
        self.date = date
    }
}
