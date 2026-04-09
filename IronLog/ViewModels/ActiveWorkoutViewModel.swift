import SwiftUI
import SwiftData
import Combine

@Observable
class ActiveWorkoutViewModel {
    var workout: Workout
    private var modelContext: ModelContext
    var elapsedSeconds: Int = 0
    var isFinished = false
    private var timer: AnyCancellable?

    init(workout: Workout, modelContext: ModelContext) {
        self.workout = workout
        self.modelContext = modelContext
        startTimer()
    }

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.elapsedSeconds = Int(self.workout.duration)
            }
    }

    func addExercise(_ exercise: Exercise) {
        let order = workout.exercises.count
        let we = WorkoutExercise(exerciseOrder: order)
        we.exercise = exercise
        we.workout = workout
        modelContext.insert(we)
        let firstSet = WorkoutSet(setNumber: 1)
        firstSet.workoutExercise = we
        modelContext.insert(firstSet)
        try? modelContext.save()
    }

    func addSet(to workoutExercise: WorkoutExercise) {
        let nextNumber = (workoutExercise.sortedSets.last?.setNumber ?? 0) + 1
        // Copy previous set's weight/reps as a starting point
        let prev = workoutExercise.sortedSets.last
        let newSet = WorkoutSet(
            setNumber: nextNumber,
            weightKg: prev?.weightKg,
            reps: prev?.reps,
            setType: prev?.setType ?? "normal"
        )
        newSet.workoutExercise = workoutExercise
        modelContext.insert(newSet)
        try? modelContext.save()
    }

    func deleteSet(_ set: WorkoutSet, from workoutExercise: WorkoutExercise) {
        modelContext.delete(set)
        // Renumber remaining sets
        workoutExercise.sortedSets.enumerated().forEach { idx, s in s.setNumber = idx + 1 }
        try? modelContext.save()
    }

    func deleteExercise(_ workoutExercise: WorkoutExercise) {
        modelContext.delete(workoutExercise)
        workout.exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }
            .enumerated().forEach { idx, e in e.exerciseOrder = idx }
        try? modelContext.save()
    }

    func finishWorkout() {
        workout.endTime = Date()
        workout.isInProgress = false
        isFinished = true
        timer?.cancel()
        try? modelContext.save()
    }

    func cancelWorkout() {
        timer?.cancel()
        modelContext.delete(workout)
        try? modelContext.save()
    }

    var formattedDuration: String {
        let h = elapsedSeconds / 3600
        let m = (elapsedSeconds % 3600) / 60
        let s = elapsedSeconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    deinit { timer?.cancel() }
}
