import SwiftUI
import SwiftData

/// Edit the active calorie/macro target. Saving creates a new dated target so
/// history is preserved.
struct TargetEditorView: View {
    let existing: NutritionTarget?
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var kcal: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double

    init(existing: NutritionTarget?) {
        self.existing = existing
        _kcal = State(initialValue: existing?.kcal ?? 2000)
        _protein = State(initialValue: existing?.proteinG ?? 150)
        _carbs = State(initialValue: existing?.carbsG ?? 200)
        _fat = State(initialValue: existing?.fatG ?? 60)
    }

    /// Calories implied by the macro split, for a sanity check.
    private var impliedKcal: Double { protein * 4 + carbs * 4 + fat * 9 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily targets") {
                    macroField("Calories", value: $kcal, unit: "kcal", step: 50)
                    macroField("Protein", value: $protein, unit: "g", step: 5)
                    macroField("Carbs", value: $carbs, unit: "g", step: 5)
                    macroField("Fat", value: $fat, unit: "g", step: 5)
                }
                Section {
                    LabeledContent("Calories from macros", value: "\(Int(impliedKcal)) kcal")
                } footer: {
                    Text("Protein & carbs = 4 kcal/g, fat = 9 kcal/g. Adjust so this is close to your calorie target.")
                }
            }
            .navigationTitle("Macro Targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
        }
    }

    private func macroField(_ label: String, value: Binding<Double>, unit: String, step: Double) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField(label, value: value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
            Stepper(label, value: value, in: 0...10000, step: step).labelsHidden()
            Text(unit).foregroundStyle(.secondary).frame(width: 36, alignment: .leading)
        }
    }

    private func save() {
        let target = NutritionTarget(
            effectiveDate: Date(),
            kcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat
        )
        context.insert(target)
        dismiss()
    }
}
