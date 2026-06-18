import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

/// The user's active calorie/macro goal. Most recent effectiveDate wins.
@Model
final class NutritionTarget {
    var effectiveDate: Date = Date()
    var kcal: Double = 2000
    var proteinG: Double = 150
    var carbsG: Double = 200
    var fatG: Double = 60

    init(
        effectiveDate: Date = Date(),
        kcal: Double = 2000,
        proteinG: Double = 150,
        carbsG: Double = 200,
        fatG: Double = 60
    ) {
        self.effectiveDate = effectiveDate
        self.kcal = kcal
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}

@Model
final class Meal {
    var date: Date = Date()
    var mealTypeRaw: String = MealType.snack.rawValue

    @Relationship(deleteRule: .cascade, inverse: \FoodEntry.meal)
    var items: [FoodEntry]? = []

    init(date: Date = Date(), mealType: MealType = .snack) {
        self.date = date
        self.mealTypeRaw = mealType.rawValue
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snack }
        set { mealTypeRaw = newValue.rawValue }
    }

    var totalKcal: Double { (items ?? []).reduce(0) { $0 + $1.kcal } }
    var totalProtein: Double { (items ?? []).reduce(0) { $0 + $1.proteinG } }
    var totalCarbs: Double { (items ?? []).reduce(0) { $0 + $1.carbsG } }
    var totalFat: Double { (items ?? []).reduce(0) { $0 + $1.fatG } }
}

@Model
final class FoodEntry {
    var name: String = ""
    var serving: String = ""
    var quantity: Double = 1
    var kcal: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0

    var meal: Meal?

    init(
        name: String = "",
        serving: String = "",
        quantity: Double = 1,
        kcal: Double = 0,
        proteinG: Double = 0,
        carbsG: Double = 0,
        fatG: Double = 0
    ) {
        self.name = name
        self.serving = serving
        self.quantity = quantity
        self.kcal = kcal
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
    }
}
