import SwiftUI
import SwiftData

/// Add / configure / remove tracked supplements (fiber, collagen, vitamins…).
struct SupplementsManageView: View {
    @Environment(\.modelContext) private var context
    @State private var config = AppConfig.shared
    @Query(sort: \Supplement.order) private var supplements: [Supplement]

    @State private var name = ""
    @State private var dose = ""
    @State private var emoji = "💊"
    @State private var target = 1

    private var t: AppTheme { config.theme }
    private let emojiChoices = ["💊", "🌿", "🟡", "🐟", "🥛", "✨", "🧴", "💪", "🫐", "🧬"]

    var body: some View {
        Form {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(emojiChoices, id: \.self) { e in
                            Text(e).font(.system(size: 22))
                                .frame(width: 40, height: 40)
                                .background(emoji == e ? t.accentSoft : t.surface2,
                                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .onTapGesture { emoji = e }
                        }
                    }
                    .padding(.vertical, 2)
                }
                TextField("Name (e.g. Collagen, Vitamin D)", text: $name)
                TextField("Dose (optional, e.g. 5 g / 1000 IU)", text: $dose)
                Stepper("Times per day: \(target)", value: $target, in: 1...10)
                Button("Add supplement") {
                    let s = Supplement(name: name.trimmingCharacters(in: .whitespaces),
                                       emoji: emoji, dose: dose, dailyTarget: target,
                                       order: (supplements.last?.order ?? -1) + 1)
                    context.insert(s)
                    name = ""; dose = ""; emoji = "💊"; target = 1
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            } header: {
                Text("New supplement")
            }

            Section("Tracked") {
                if supplements.isEmpty {
                    Text("Nothing yet.").foregroundStyle(.secondary)
                }
                ForEach(supplements) { s in
                    HStack(spacing: 10) {
                        Text(s.emoji)
                        VStack(alignment: .leading) {
                            Text(s.name)
                            Text("\(s.dose.isEmpty ? "" : s.dose + " · ")\(s.dailyTarget)×/day")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { offsets in
                    for i in offsets { context.delete(supplements[i]) }
                }
            }
        }
        .navigationTitle("Supplements")
        .navigationBarTitleDisplayMode(.inline)
        .tint(t.accent)
        .airyBackground(t)
    }
}
