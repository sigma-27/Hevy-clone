import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var selectedMuscle: String? = nil
    @State private var selectedEquipment: String? = nil
    @State private var showingCreateExercise = false

    private var filtered: [Exercise] {
        exercises.filter { ex in
            let matchSearch = searchText.isEmpty || ex.name.localizedCaseInsensitiveContains(searchText)
            let matchMuscle = selectedMuscle == nil ||
                ex.primaryMuscles.contains(selectedMuscle!) ||
                ex.secondaryMuscles.contains(selectedMuscle!)
            let matchEquip = selectedEquipment == nil || ex.equipment == selectedEquipment
            return matchSearch && matchMuscle && matchEquip
        }
    }

    private var grouped: [(String, [Exercise])] {
        Dictionary(grouping: filtered, by: { String($0.name.prefix(1)).uppercased() })
            .sorted { $0.key < $1.key }
    }

    var body: some View {
        NavigationStack {
            Group {
                if exercises.isEmpty {
                    EmptyStateView(title: "No Exercises", message: "Exercise library is loading…", systemImage: "books.vertical")
                } else {
                    List {
                        // Filter chips
                        if selectedMuscle != nil || selectedEquipment != nil {
                            Section {
                                filterChips
                            }
                        }
                        ForEach(grouped, id: \.0) { letter, exs in
                            Section(letter) {
                                ForEach(exs) { exercise in
                                    NavigationLink(destination: ExerciseDetailView(exercise: exercise)) {
                                        ExerciseRowView(exercise: exercise)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreateExercise = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItemGroup(placement: .topBarLeading) {
                    muscleFilterMenu
                    equipmentFilterMenu
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                CreateExerciseView()
            }
        }
    }

    private var filterChips: some View {
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

    private func filterChip(_ label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label).font(.caption)
            Button(action: onRemove) { Image(systemName: "xmark").font(.caption2) }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.15)).foregroundStyle(.accentColor)
        .clipShape(Capsule())
    }

    private var muscleFilterMenu: some View {
        Menu {
            Button("All Muscles") { selectedMuscle = nil }
            Divider()
            ForEach(["chest","back","shoulders","biceps","triceps","quadriceps","hamstrings","glutes","abs","calves","lower_back","traps"], id: \.self) { muscle in
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
            Image(systemName: selectedMuscle != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .foregroundStyle(selectedMuscle != nil ? Color.accentColor : Color.primary)
        }
    }

    private var equipmentFilterMenu: some View {
        Menu {
            Button("All Equipment") { selectedEquipment = nil }
            Divider()
            ForEach(["barbell","dumbbell","cable","machine","bodyweight","bands","kettlebell","other"], id: \.self) { equip in
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
    }
}
