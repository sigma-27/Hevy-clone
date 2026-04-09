import SwiftUI
import SwiftData

struct ExerciseInWorkoutView: View {
    @Bindable var workoutExercise: WorkoutExercise
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var showingNotes = false

    private var useKg: Bool { settings.first?.useKilograms ?? true }
    private var restSeconds: TimeInterval { Double(settings.first?.restTimerDefaultSeconds ?? 90) }
    private var autoStart: Bool { settings.first?.autoStartRestTimer ?? true }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                if let sg = workoutExercise.supersetGroup {
                    Text("SS\(sg)").font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2)).foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
                Text(workoutExercise.exercise?.name ?? "Exercise")
                    .font(.headline).fontWeight(.semibold)
                Spacer()
                Menu {
                    Button { showingNotes.toggle() } label: { Label("Notes", systemImage: "note.text") }
                    Button(role: .destructive) { deleteExercise() } label: {
                        Label("Remove", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis").padding(8)
                }
            }
            .padding(.horizontal).padding(.top, 12)

            // Notes
            if showingNotes {
                TextField("Exercise notes", text: $workoutExercise.notes, axis: .vertical)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(.horizontal).padding(.top, 4)
            }

            // Column headers
            HStack(spacing: 0) {
                Text("SET").frame(width: 44)
                Text("PREVIOUS").frame(maxWidth: .infinity)
                Text(useKg ? "KG" : "LBS").frame(width: 70)
                Text("REPS").frame(width: 60)
                Image(systemName: "checkmark").frame(width: 44)
            }
            .font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
            .padding(.horizontal, 8).padding(.vertical, 8)

            // Sets
            ForEach(workoutExercise.sortedSets) { set in
                SetRowView(set: set, setIndex: set.setNumber - 1, useKg: useKg) {
                    if autoStart { appState.startRestTimer(seconds: restSeconds) }
                }
            }

            // Add set
            Button {
                let nextNum = (workoutExercise.sets.map(\.setNumber).max() ?? 0) + 1
                let prev = workoutExercise.sortedSets.last
                let newSet = WorkoutSet(setNumber: nextNum, weightKg: prev?.weightKg, reps: prev?.reps)
                newSet.workoutExercise = workoutExercise
                modelContext.insert(newSet)
                workoutExercise.sets.append(newSet)
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 10)
                    .foregroundStyle(.accentColor)
            }
            .padding(.horizontal, 8)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func deleteExercise() {
        if let workout = workoutExercise.workout {
            workout.exercises.removeAll { $0.id == workoutExercise.id }
        }
        modelContext.delete(workoutExercise)
    }
}
