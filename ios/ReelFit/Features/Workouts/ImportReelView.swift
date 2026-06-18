import SwiftUI
import SwiftData

/// Drives the "reel → structured workout" flow: call the backend, preview the
/// result, and save it. Handles the manual-caption fallback.
struct ImportReelView: View {
    let target: ImportTarget

    @Environment(\.modelContext) private var context
    @Environment(PendingReels.self) private var pending
    @Environment(\.dismiss) private var dismiss

    @State private var url: String
    @State private var caption: String = ""
    @State private var showCaptionField = false
    @State private var phase: Phase = .input
    @State private var result: ExtractedWorkout?
    @State private var errorText: String?

    private let client = BackendClient()

    enum Phase { case input, loading, preview }

    init(target: ImportTarget) {
        self.target = target
        _url = State(initialValue: target.prefilledURL)
    }

    var body: some View {
        NavigationStack {
            Form {
                switch phase {
                case .input, .loading:
                    inputSection
                case .preview:
                    previewSection
                }

                if let errorText {
                    Section {
                        Text(errorText).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Import Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if phase == .preview {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { save() }
                    }
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder private var inputSection: some View {
        Section("Instagram reel link") {
            TextField("https://www.instagram.com/reel/…", text: $url)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
        }

        if showCaptionField {
            Section {
                TextEditor(text: $caption).frame(minHeight: 140)
            } header: {
                Text("Paste the caption")
            } footer: {
                Text("We couldn't read this reel automatically. Open it in Instagram, copy the caption, and paste it here.")
            }
        }

        Section {
            Button {
                Task { await extract() }
            } label: {
                if phase == .loading {
                    HStack { ProgressView(); Text("Extracting…") }
                } else {
                    Text(showCaptionField ? "Extract from caption" : "Extract workout")
                }
            }
            .disabled(url.isEmpty || phase == .loading)
        }
    }

    @ViewBuilder private var previewSection: some View {
        if let result {
            Section {
                Text(result.title).font(.headline)
                if !result.summary.isEmpty {
                    Text(result.summary).foregroundStyle(.secondary)
                }
                Label(WorkoutCategory(rawValue: result.category)?.title ?? "Other",
                      systemImage: "tag")
            }
            Section("Moves (\(result.exercises.count))") {
                ForEach(Array(result.exercises.enumerated()), id: \.offset) { _, ex in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(ex.name).font(.subheadline.weight(.semibold))
                            Spacer()
                            if let p = prescription(ex) {
                                Text(p).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        if !ex.instructions.isEmpty {
                            Text(ex.instructions).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func extract() async {
        errorText = nil
        phase = .loading
        do {
            let captionArg = showCaptionField && !caption.isEmpty ? caption : nil
            let workout = try await client.extractReel(url: url, caption: captionArg)
            if workout.needsManualCaption {
                showCaptionField = true
                phase = .input
                errorText = "Couldn't read this reel. Paste its caption below and try again."
                return
            }
            if workout.exercises.isEmpty {
                showCaptionField = true
                phase = .input
                errorText = "No exercises found. Try pasting the caption."
                return
            }
            result = workout
            phase = .preview
        } catch {
            phase = .input
            errorText = error.localizedDescription
        }
    }

    private func save() {
        guard let result else { return }
        let workout = WorkoutTemplate(
            title: result.title,
            category: WorkoutCategory(rawValue: result.category) ?? .other,
            summary: result.summary,
            sourceURL: result.sourceURL,
            thumbnailURL: result.thumbnailURL,
            caption: result.caption ?? caption
        )
        context.insert(workout)
        for (i, ex) in result.exercises.enumerated() {
            let exercise = Exercise(
                name: ex.name,
                instructions: ex.instructions,
                sets: ex.sets,
                reps: ex.reps,
                durationSec: ex.durationSec,
                restSec: ex.restSec,
                equipment: ex.equipment,
                order: i
            )
            exercise.template = workout
            context.insert(exercise)
        }
        if let reel = target.sharedReel {
            pending.remove(reel)
        }
        dismiss()
    }

    private func prescription(_ ex: ExtractedExercise) -> String? {
        if let s = ex.sets, let r = ex.reps { return "\(s) × \(r)" }
        if let r = ex.reps { return "\(r) reps" }
        if let d = ex.durationSec { return "\(d)s" }
        return nil
    }
}
