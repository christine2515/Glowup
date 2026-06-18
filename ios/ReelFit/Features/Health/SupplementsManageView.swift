import SwiftUI
import SwiftData

/// Add / remove the supplements you want to track.
struct SupplementsManageView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Supplement.createdAt) private var supplements: [Supplement]

    @State private var name = ""
    @State private var dose = ""
    @State private var target = 1

    var body: some View {
        Form {
            Section("New supplement") {
                TextField("Name (e.g. Creatine)", text: $name)
                TextField("Dose (e.g. 5 g)", text: $dose)
                Stepper("Times per day: \(target)", value: $target, in: 1...10)
                Button("Add") {
                    let s = Supplement(name: name, dose: dose, dailyTarget: target)
                    context.insert(s)
                    name = ""; dose = ""; target = 1
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Section("Tracked") {
                if supplements.isEmpty {
                    Text("Nothing yet.").foregroundStyle(.secondary)
                }
                ForEach(supplements) { s in
                    VStack(alignment: .leading) {
                        Text(s.name)
                        Text("\(s.dose.isEmpty ? "" : s.dose + " · ")\(s.dailyTarget)×/day")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .onDelete { offsets in
                    for i in offsets { context.delete(supplements[i]) }
                }
            }
        }
        .navigationTitle("Supplements")
        .navigationBarTitleDisplayMode(.inline)
    }
}
