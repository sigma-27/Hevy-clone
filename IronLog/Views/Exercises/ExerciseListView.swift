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
                ToolbarItem(placement: .topBarLeading) {
                    muscleFilterMenu
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                CreateExerciseView()
            }
        }
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if let m = selectedMuscle {
                    filterChip(m.replacingOccurrences(of: "_", with: " ").capitalized) {
                        selectedMuscle = nil
                    }
                }
                if let e = selectedEquipment {
                    filterChip(e.capitalized) { selectedEquipment = nil }
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

    private var muscleFilterMenu: some View {
        Menu {
            ForEach(["chest","back","shoulders","biceps","triceps","quadriceps","hamstrings","glutes","abs","calves"], id: \.self) { muscle in
                Button(muscle.capitalized) { selectedMuscle = muscle }
            }
        } label: {
            Image(systemName: selectedMuscle != nil ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }
}
