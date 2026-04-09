import SwiftUI
import SwiftData

struct ExerciseInWorkoutView: View {
    @Bindable var workoutExercise: WorkoutExercise
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \Workout.startTime, order: .reverse) private var allWorkouts: [Workout]
    @State private var showingNotes = false

    private var useKg: Bool { settings.first?.useKilograms ?? true }
    private var restSeconds: TimeInterval { Double(settings.first?.restTimerDefaultSeconds ?? 90) }
    private var autoStart: Bool { settings.first?.autoStartRestTimer ?? true }
    private var showRPE: Bool { settings.first?.showRPE ?? true }

    /// Previous completed sets for this exercise (from most recent completed workout)
    private var previousSets: [WorkoutSet] {
        guard let exerciseID = workoutExercise.exercise?.id else { return [] }
        let currentWorkoutID = workoutExercise.workout?.id
        for workout in allWorkouts {
            guard !workout.isInProgress, workout.id != currentWorkoutID else { continue }
            let we = workout.exercises.first { $0.exercise?.id == exerciseID }
            if let we {
                return we.sortedSets.filter { $0.isCompleted }
            }
        }
        return []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                if let sg = workoutExercise.supersetGroup {
                    Text("SS\(sg)").font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2)).foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
                NavigationLink(destination: ExerciseDetailView(exercise: workoutExercise.exercise!)) {
                    Text(workoutExercise.exercise?.name ?? "Exercise")
                        .font(.headline).fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .disabled(workoutExercise.exercise == nil)
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

            // Notes field
            if showingNotes {
                TextField("Notes for this exercise…", text: $workoutExercise.notes, axis: .vertical)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .padding(.horizontal).padding(.top, 4)
            }

            // Column headers
            HStack(spacing: 0) {
                Text("SET").frame(width: 44)
                Text("PREV").frame(maxWidth: .infinity)
                Text(useKg ? "KG" : "LBS").frame(width: 70)
                Text("REPS").frame(width: 56)
                if showRPE { Text("RPE").frame(width: 36) }
                Image(systemName: "checkmark").frame(width: 44)
            }
            .font(.caption2).fontWeight(.semibold).foregroundStyle(.secondary)
            .padding(.horizontal, 8).padding(.vertical, 8)

            // Set rows
            ForEach(workoutExercise.sortedSets) { set in
                let prevSet = previousSets.first { $0.setNumber == set.setNumber }
                SetRowView(
                    set: set,
                    setIndex: set.setNumber - 1,
                    useKg: useKg,
                    previousWeightKg: prevSet?.weightKg,
                    previousReps: prevSet?.reps,
                    showRPE: showRPE
                ) {
                    if autoStart { appState.startRestTimer(seconds: restSeconds) }
                }
            }

            // Add set button
            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "plus")
                    .font(.subheadline).frame(maxWidth: .infinity).padding(.vertical, 10)
                    .foregroundStyle(.accentColor)
            }
            .padding(.horizontal, 8).padding(.bottom, 4)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func addSet() {
        let nextNum = (workoutExercise.sets.map(\.setNumber).max() ?? 0) + 1
        let prev = workoutExercise.sortedSets.last
        let newSet = WorkoutSet(setNumber: nextNum, weightKg: prev?.weightKg, reps: prev?.reps)
        newSet.workoutExercise = workoutExercise
        modelContext.insert(newSet)
        workoutExercise.sets.append(newSet)
    }

    private func deleteExercise() {
        if let workout = workoutExercise.workout {
            workout.exercises.removeAll { $0.id == workoutExercise.id }
        }
        modelContext.delete(workoutExercise)
    }
}
