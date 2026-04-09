import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    var onSelect: (Exercise) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscle: String? = nil
    @State private var selectedEquipment: String? = nil

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchSearch = searchText.isEmpty ||
                ex.name.localizedCaseInsensitiveContains(searchText)
            let matchMuscle = selectedMuscle == nil ||
                ex.primaryMuscles.contains(selectedMuscle!) ||
                ex.secondaryMuscles.contains(selectedMuscle!)
            let matchEquip = selectedEquipment == nil || ex.equipment == selectedEquipment
            return matchSearch && matchMuscle && matchEquip
        }
    }

    private var grouped: [(String, [Exercise])] {
        let g = Dictionary(grouping: filtered, by: { $0.category })
        return g.sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { category, exs in
                    Section(category) {
                        ForEach(exs) { exercise in
                            Button {
                                onSelect(exercise)
                                dismiss()
                            } label: {
                                ExerciseRowView(exercise: exercise)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct ExerciseRowView: View {
    var exercise: Exercise
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name).font(.subheadline)
            HStack(spacing: 6) {
                Text(exercise.equipment.capitalized)
                    .font(.caption2).foregroundStyle(.secondary)
                ForEach(exercise.primaryMuscles.prefix(2), id: \.self) { m in
                    MuscleGroupBadge(muscle: m, isPrimary: true)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
