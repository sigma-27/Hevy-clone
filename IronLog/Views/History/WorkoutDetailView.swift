import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    var workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            // Stats header
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    statCell(String(format: "%.0f kg", workout.totalVolumeKg), label: "Volume")
                    statCell(durationLabel, label: "Duration")
                    statCell("\(workout.completedSetsCount)", label: "Sets")
                }
                .padding(.vertical, 4)
            }

            // Notes
            if !workout.notes.isEmpty {
                Section("Notes") { Text(workout.notes).font(.subheadline) }
            }

            // Exercises
            ForEach(workout.exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }) { we in
                Section(we.exercise?.name ?? "Exercise") {
                    ForEach(we.sortedSets) { set in
                        HStack {
                            Text("Set \(set.setNumber)").font(.subheadline).foregroundStyle(.secondary)
                            Spacer()
                            if let w = set.weightKg, let r = set.reps {
                                Text("\(Int(w)) kg × \(r)")
                                    .font(.subheadline).fontWeight(.semibold)
                            } else if let d = set.durationSeconds {
                                Text("\(d / 60):\(String(format: "%02d", d % 60))")
                                    .font(.subheadline).fontWeight(.semibold)
                            }
                            if let rpe = set.rpe {
                                Text("RPE \(rpe.formatted(.number.precision(.fractionLength(1))))")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Redo") { redoWorkout() }
            }
        }
    }

    private var durationLabel: String {
        let m = Int(workout.duration / 60)
        return m < 60 ? "\(m)m" : "\(m/60)h \(m%60)m"
    }

    private func statCell(_ value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func redoWorkout() {
        let newWorkout = Workout(title: workout.title)
        for (i, we) in workout.exercises.sorted(by: { $0.exerciseOrder < $1.exerciseOrder }).enumerated() {
            let newWE = WorkoutExercise(exerciseOrder: i)
            newWE.exercise = we.exercise
            newWE.workout = newWorkout
            let setCount = max(1, we.sortedSets.count)
            for j in 0..<setCount {
                let refSet = we.sortedSets.first
                let newSet = WorkoutSet(setNumber: j + 1, weightKg: refSet?.weightKg, reps: refSet?.reps)
                newWE.sets.append(newSet)
                modelContext.insert(newSet)
            }
            newWorkout.exercises.append(newWE)
            modelContext.insert(newWE)
        }
        modelContext.insert(newWorkout)
        appState.startWorkout(newWorkout)
    }
}
