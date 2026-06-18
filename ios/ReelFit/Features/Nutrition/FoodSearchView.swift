import SwiftUI
import SwiftData

/// Search the USDA food database (via the backend) and add items to a meal.
/// Falls back to manual entry if the backend isn't configured.
struct FoodSearchView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Meal.date, order: .reverse) private var allMeals: [Meal]

    @State private var mealType: MealType = currentMealType()
    @State private var query = ""
    @State private var results: [FoodResult] = []
    @State private var loading = false
    @State private var errorText: String?
    @State private var addedCount = 0

    private let client = BackendClient()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    HStack {
                        TextField("Search foods (e.g. banana)", text: $query)
                            .onSubmit { Task { await search() } }
                        if loading { ProgressView() }
                    }
                    Button("Search") { Task { await search() } }
                        .disabled(query.isEmpty || loading)
                }

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                }

                if !results.isEmpty {
                    Section("Results") {
                        ForEach(results) { food in
                            Button { add(food) } label: { FoodResultRow(food: food) }
                        }
                    }
                }

                Section("Add manually") {
                    NavigationLink("Custom food…") {
                        ManualFoodView { entry in
                            attach(entry: entry)
                        }
                    }
                }
            }
            .navigationTitle(addedCount == 0 ? "Add Food" : "Added \(addedCount)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }

    // MARK: - Actions

    private func search() async {
        errorText = nil
        loading = true
        defer { loading = false }
        do {
            results = try await client.searchFood(query)
            if results.isEmpty { errorText = "No results. Try a simpler term, or add manually." }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func add(_ food: FoodResult) {
        let entry = FoodEntry(
            name: food.name, serving: food.serving, quantity: 1,
            kcal: food.kcal, proteinG: food.proteinG, carbsG: food.carbsG, fatG: food.fatG
        )
        attach(entry: entry)
    }

    private func attach(entry: FoodEntry) {
        let meal = mealForToday(mealType)
        entry.meal = meal
        context.insert(entry)
        addedCount += 1
    }

    private func mealForToday(_ type: MealType) -> Meal {
        if let existing = allMeals.first(where: {
            $0.mealType == type && Calendar.current.isDateInToday($0.date)
        }) {
            return existing
        }
        let meal = Meal(date: Date(), mealType: type)
        context.insert(meal)
        return meal
    }
}

private struct FoodResultRow: View {
    let food: FoodResult
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(food.name).font(.subheadline).foregroundStyle(.primary)
            Text("\(Int(food.kcal)) kcal · P\(Int(food.proteinG)) C\(Int(food.carbsG)) F\(Int(food.fatG)) · \(food.serving)")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

/// Helper used by FoodSearchView and meal suggestions for manual entry.
struct ManualFoodView: View {
    var onAdd: (FoodEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var kcal = 0.0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0

    var body: some View {
        Form {
            TextField("Name", text: $name)
            numberField("Calories", $kcal, "kcal")
            numberField("Protein", $protein, "g")
            numberField("Carbs", $carbs, "g")
            numberField("Fat", $fat, "g")
            Button("Add") {
                onAdd(FoodEntry(name: name, serving: "1 serving", quantity: 1,
                                kcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat))
                dismiss()
            }
            .disabled(name.isEmpty)
        }
        .navigationTitle("Custom Food")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func numberField(_ label: String, _ value: Binding<Double>, _ unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad).multilineTextAlignment(.trailing).frame(width: 80)
            Text(unit).foregroundStyle(.secondary)
        }
    }
}

/// Best-guess meal type based on the time of day.
func currentMealType() -> MealType {
    switch Calendar.current.component(.hour, from: Date()) {
    case 5..<11: return .breakfast
    case 11..<15: return .lunch
    case 15..<18: return .snack
    default: return .dinner
    }
}
