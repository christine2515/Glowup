import SwiftUI
import SwiftData

/// AI meal suggestions that fit the remaining macro budget. Tap one to log it.
struct MealSuggestionsView: View {
    let remaining: MacroBudget

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Meal.date, order: .reverse) private var allMeals: [Meal]

    @State private var mealType: MealType = currentMealType()
    @State private var preferences = ""
    @State private var suggestions: [MealSuggestion] = []
    @State private var loading = false
    @State private var errorText: String?

    private let client = BackendClient()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Remaining today",
                                   value: "\(Int(remaining.kcal)) kcal · P\(Int(remaining.proteinG)) C\(Int(remaining.carbsG)) F\(Int(remaining.fatG))")
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { Text($0.title).tag($0) }
                    }
                    TextField("Preferences (e.g. high protein, vegetarian)", text: $preferences)
                    Button { Task { await load() } } label: {
                        if loading { HStack { ProgressView(); Text("Thinking…") } }
                        else { Text("Get suggestions") }
                    }
                    .disabled(loading)
                }

                if let errorText {
                    Section { Text(errorText).foregroundStyle(.red) }
                }

                ForEach(suggestions) { s in
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(s.name).font(.headline)
                            Text(s.description).font(.subheadline).foregroundStyle(.secondary)
                            Text("\(Int(s.kcal)) kcal · P\(Int(s.proteinG)) C\(Int(s.carbsG)) F\(Int(s.fatG))")
                                .font(.caption).foregroundStyle(.secondary)
                            if !s.ingredients.isEmpty {
                                Text(s.ingredients.joined(separator: ", "))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                            Button("Log this meal") { log(s) }
                                .buttonStyle(.borderedProminent)
                                .padding(.top, 2)
                        }
                    }
                }
            }
            .navigationTitle("Meal Ideas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task { await load() }
        }
    }

    private func load() async {
        errorText = nil
        loading = true
        defer { loading = false }
        do {
            suggestions = try await client.recommendMeals(
                remaining: remaining, mealType: mealType.rawValue, preferences: preferences
            )
            if suggestions.isEmpty { errorText = "No suggestions came back. Try again." }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func log(_ s: MealSuggestion) {
        let meal = allMeals.first {
            $0.mealType == mealType && Calendar.current.isDateInToday($0.date)
        } ?? {
            let m = Meal(date: Date(), mealType: mealType)
            context.insert(m)
            return m
        }()
        let entry = FoodEntry(
            name: s.name, serving: "1 serving", quantity: 1,
            kcal: s.kcal, proteinG: s.proteinG, carbsG: s.carbsG, fatG: s.fatG
        )
        entry.meal = meal
        context.insert(entry)
        dismiss()
    }
}
