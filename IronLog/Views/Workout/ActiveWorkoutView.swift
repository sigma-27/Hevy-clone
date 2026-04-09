import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var workout: Workout
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var allExercises: [Exercise]
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirm = false
    @State private var showingComplete = false
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Rest timer banner
                    if appState.isRestTimerRunning {
                        RestTimerView(
                            remaining: appState.restTimerRemaining,
                            total: appState.restTimerTotal,
                            onSkip: { appState.stopRestTimer() },
                            onAddTime: { appState.addRestTime($0) }
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    // Exercise list
                    LazyVStack(spacing: 16, pinnedViews: []) {
                        ForEach(workout.exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }) { we in
                            ExerciseInWorkoutView(workoutExercise: we)
                        }
                    }
                    .padding()

                    // Add exercise button
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(elapsedString)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Finish") { showingFinishConfirm = true }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView { exercise in
                    addExercise(exercise)
                    showingExercisePicker = false
                }
            }
            .sheet(isPresented: $showingComplete) {
                WorkoutCompleteView(workout: workout) {
                    showingComplete = false
                    appState.endWorkout()
                }
                .presentationDetents([.medium, .large])
            }
            .confirmationDialog("Finish Workout?", isPresented: $showingFinishConfirm, titleVisibility: .visible) {
                Button("Finish Workout", role: .none) { finishWorkout() }
                Button("Cancel Workout", role: .destructive) { cancelWorkout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You've completed \(workout.completedSetsCount) sets.")
            }
        }
        .onAppear {
            startTimer()
            RestTimerService.requestPermission()
        }
        .onDisappear { timer?.invalidate() }
    }

    private var elapsedString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }

    private func startTimer() {
        elapsedSeconds = Int(Date().timeIntervalSince(workout.startTime))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedSeconds += 1
        }
    }

    private func addExercise(_ exercise: Exercise) {
        let we = WorkoutExercise(exerciseOrder: workout.exercises.count)
        we.exercise = exercise
        we.workout = workout
        let set = WorkoutSet(setNumber: 1)
        we.sets.append(set)
        modelContext.insert(we)
        modelContext.insert(set)
        workout.exercises.append(we)
    }

    private func finishWorkout() {
        workout.endTime = Date()
        workout.isInProgress = false
        applyAutoProgression()
        try? modelContext.save()
        showingComplete = true
    }

    /// If this workout matches a routine (by title), apply auto-progression to matching exercises.
    private func applyAutoProgression() {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { $0.name == workout.title }
        )
        guard let routines = try? modelContext.fetch(descriptor),
              let routine = routines.first else { return }

        for we in workout.exercises {
            guard let exerciseID = we.exercise?.id else { continue }
            guard let re = routine.exercises.first(where: { $0.exercise?.id == exerciseID }),
                  re.autoProgressEnabled else { continue }

            // Parse target reps range e.g. "8-12" or "5"
            let parts = re.targetReps.components(separatedBy: "-").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            let targetRepsTop = parts.last ?? 0
            guard targetRepsTop > 0 else { continue }

            // Check if all completed sets hit the top of the rep range
            let completedSets = we.sortedSets.filter { $0.isCompleted }
            let allHitTarget = !completedSets.isEmpty &&
                completedSets.allSatisfy { ($0.reps ?? 0) >= targetRepsTop }

            if allHitTarget {
                re.targetWeightKg = (re.targetWeightKg ?? 0) + re.autoProgressWeightKg
            }
        }
    }

    private func cancelWorkout() {
        modelContext.delete(workout)
        try? modelContext.save()
        appState.endWorkout()
    }
}
