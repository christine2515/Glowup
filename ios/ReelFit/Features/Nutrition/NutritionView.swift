import SwiftUI
import SwiftData

/// Nutrition tab: macro rings vs target, today's meals, food search, and AI
/// meal suggestions that fit your remaining macros.
struct NutritionView: View {
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared

    @Query(sort: \NutritionTarget.effectiveDate, order: .reverse)
    private var targets: [NutritionTarget]
    @Query(sort: \Meal.date, order: .reverse)
    private var allMeals: [Meal]

    @State private var editingTarget = false
    @State private var addingFood = false
    @State private var suggesting = false

    private var target: NutritionTarget? { targets.first }

    private var todayMeals: [Meal] {
        allMeals.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var consumed: MacroTotals {
        todayMeals.reduce(into: MacroTotals()) { acc, meal in
            acc.kcal += meal.totalKcal
            acc.protein += meal.totalProtein
            acc.carbs += meal.totalCarbs
            acc.fat += meal.totalFat
        }
    }

    private var remaining: MacroBudget {
        let t = target
        return MacroBudget(
            kcal: max((t?.kcal ?? 2000) - consumed.kcal, 0),
            proteinG: max((t?.proteinG ?? 150) - consumed.protein, 0),
            carbsG: max((t?.carbsG ?? 200) - consumed.carbs, 0),
            fatG: max((t?.fatG ?? 60) - consumed.fat, 0)
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ringsSection
                actionsSection
                mealsSection
            }
            .navigationTitle("Nutrition")
            .toolbar {
                Button { editingTarget = true } label: {
                    Image(systemName: "target")
                }
            }
            .sheet(isPresented: $editingTarget) {
                TargetEditorView(existing: target)
            }
            .sheet(isPresented: $addingFood) {
                FoodSearchView()
            }
            .sheet(isPresented: $suggesting) {
                MealSuggestionsView(remaining: remaining)
            }
        }
    }

    private var ringsSection: some View {
        Section {
            let t = target
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    MacroRing(label: "Calories", value: consumed.kcal,
                              target: t?.kcal ?? 2000, unit: "kcal", color: config.theme.calories)
                    MacroRing(label: "Protein", value: consumed.protein,
                              target: t?.proteinG ?? 150, unit: "g", color: config.theme.protein)
                    MacroRing(label: "Carbs", value: consumed.carbs,
                              target: t?.carbsG ?? 200, unit: "g", color: config.theme.carbs)
                    MacroRing(label: "Fat", value: consumed.fat,
                              target: t?.fatG ?? 60, unit: "g", color: config.theme.fat)
                }
                .padding(.vertical, 4)
            }
            if target == nil {
                Text("Using default targets — tap the target icon to set yours.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .listRowBackground(config.theme.wash)
    }

    private var actionsSection: some View {
        Section {
            Button { addingFood = true } label: {
                Label("Add food", systemImage: "plus.circle.fill")
            }
            Button { suggesting = true } label: {
                Label("Suggest a meal for my remaining macros", systemImage: "sparkles")
            }
        }
    }

    private var mealsSection: some View {
        Section("Today's meals") {
            if todayMeals.isEmpty {
                Text("No meals logged yet.").foregroundStyle(.secondary)
            }
            ForEach(todayMeals) { meal in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(meal.mealType.title).font(.headline)
                        Spacer()
                        Text("\(Int(meal.totalKcal)) kcal")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    ForEach(meal.items ?? []) { item in
                        HStack {
                            Text(item.name).font(.subheadline)
                            Spacer()
                            Text("\(Int(item.kcal)) kcal")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .onDelete(perform: deleteMeals)
        }
    }

    private func deleteMeals(_ offsets: IndexSet) {
        let meals = todayMeals
        for i in offsets { context.delete(meals[i]) }
    }
}
