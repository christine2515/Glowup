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

/// A supplement the user wants to take, with a simple daily target count.
@Model
final class Supplement {
    var name: String = ""
    var dose: String = ""
    var dailyTarget: Int = 1
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \SupplementLog.supplement)
    var logs: [SupplementLog]? = []

    init(name: String = "", dose: String = "", dailyTarget: Int = 1) {
        self.name = name
        self.dose = dose
        self.dailyTarget = dailyTarget
    }
}

@Model
final class SupplementLog {
    var date: Date = Date()
    var supplement: Supplement?

    init(date: Date = Date()) {
        self.date = date
    }
}
