import SwiftUI
import SwiftData

struct CreateExerciseView: View {
    var onCreated: ((Exercise) -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var category = "Strength"
    @State private var equipment = "barbell"
    @State private var primaryMuscles: Set<String> = []
    @State private var secondaryMuscles: Set<String> = []
    @State private var instructions = ""

    private let categories = ["Strength", "Cardio", "Stretching", "Olympic", "Plyometrics"]
    private let equipmentOptions = ["barbell","dumbbell","cable","machine","bodyweight","bands","kettlebell","other"]
    private let muscles = ["chest","back","shoulders","biceps","triceps","quadriceps","hamstrings","glutes","abs","calves","lower_back","traps","lats","front_delt","rear_delt","obliques"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Exercise name", text: $name)
                }
                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Equipment") {
                    Picker("Equipment", selection: $equipment) {
                        ForEach(equipmentOptions, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    .pickerStyle(.menu)
                }
                Section("Primary Muscles") {
                    ForEach(muscles, id: \.self) { muscle in
                        Toggle(muscle.replacingOccurrences(of: "_", with: " ").capitalized,
                               isOn: Binding(
                                get: { primaryMuscles.contains(muscle) },
                                set: { if $0 { primaryMuscles.insert(muscle) } else { primaryMuscles.remove(muscle) } }
                               ))
                    }
                }
                Section("Secondary Muscles (optional)") {
                    ForEach(muscles, id: \.self) { muscle in
                        Toggle(muscle.replacingOccurrences(of: "_", with: " ").capitalized,
                               isOn: Binding(
                                get: { secondaryMuscles.contains(muscle) },
                                set: { if $0 { secondaryMuscles.insert(muscle) } else { secondaryMuscles.remove(muscle) } }
                               ))
                    }
                }
                Section("Instructions (optional)") {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let exercise = Exercise(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            primaryMuscles: Array(primaryMuscles),
            secondaryMuscles: Array(secondaryMuscles),
            equipment: equipment,
            instructions: instructions,
            isCustom: true
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        onCreated?(exercise)
        dismiss()
    }
}
