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
