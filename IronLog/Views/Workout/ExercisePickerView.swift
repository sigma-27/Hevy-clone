import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    var onSelect: (Exercise) -> Void = { _ in }
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscle: String? = nil
    @State private var selectedEquipment: String? = nil
    @State private var showingCreate = false

    private let muscles = ["chest","back","shoulders","biceps","triceps","quadriceps","hamstrings","glutes","abs","calves","lower_back","traps"]
    private let equipmentOptions = ["barbell","dumbbell","cable","machine","bodyweight","bands","kettlebell","other"]

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

    private var hasActiveFilter: Bool { selectedMuscle != nil || selectedEquipment != nil }

    var body: some View {
        NavigationStack {
            List {
                // Active filter chips
                if hasActiveFilter {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                if let m = selectedMuscle {
                                    filterChip(m.replacingOccurrences(of: "_", with: " ").capitalized) {
                                        selectedMuscle = nil
                                    }
                                }
                                if let e = selectedEquipment {
                                    filterChip(e.capitalized) { selectedEquipment = nil }
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }

                if filtered.isEmpty {
                    ContentUnavailableView.search(text: searchText.isEmpty ? (selectedMuscle ?? selectedEquipment ?? "") : searchText)
                } else {
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
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Muscle filter
                    Menu {
                        Button("All Muscles") { selectedMuscle = nil }
                        Divider()
                        ForEach(muscles, id: \.self) { muscle in
                            Button {
                                selectedMuscle = muscle
                            } label: {
                                if selectedMuscle == muscle {
                                    Label(muscle.replacingOccurrences(of: "_", with: " ").capitalized, systemImage: "checkmark")
                                } else {
                                    Text(muscle.replacingOccurrences(of: "_", with: " ").capitalized)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: selectedMuscle != nil
                              ? "figure.strengthtraining.traditional"
                              : "figure.strengthtraining.traditional")
                            .symbolVariant(selectedMuscle != nil ? .fill : .none)
                            .foregroundStyle(selectedMuscle != nil ? Color.accentColor : Color.primary)
                    }

                    // Equipment filter
                    Menu {
                        Button("All Equipment") { selectedEquipment = nil }
                        Divider()
                        ForEach(equipmentOptions, id: \.self) { equip in
                            Button {
                                selectedEquipment = equip
                            } label: {
                                if selectedEquipment == equip {
                                    Label(equip.capitalized, systemImage: "checkmark")
                                } else {
                                    Text(equip.capitalized)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: selectedEquipment != nil ? "dumbbell.fill" : "dumbbell")
                            .foregroundStyle(selectedEquipment != nil ? Color.accentColor : Color.primary)
                    }

                    // Create new exercise
                    Button { showingCreate = true } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateExerciseView { exercise in
                    onSelect(exercise)
                    dismiss()
                }
            }
        }
    }

    private func filterChip(_ label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption)
            Button(action: onRemove) { Image(systemName: "xmark").font(.caption2) }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.15)).foregroundStyle(.accentColor)
        .clipShape(Capsule())
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
