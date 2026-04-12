import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var workout: Workout
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var settings: [UserSettings]
    @State private var showingExercisePicker = false
    @State private var showingFinishConfirm = false
    @State private var showingComplete = false
    @State private var showingNotes = false
    @State private var isReordering = false
    @State private var isEditingTitle = false
    @FocusState private var titleFocused: Bool
    @State private var elapsedSeconds = 0
    @State private var timer: Timer?

    private var restSeconds: TimeInterval { Double(settings.first?.restTimerDefaultSeconds ?? 90) }
    private var autoStartRest: Bool { settings.first?.autoStartRestTimer ?? true }

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

                    // Inline workout notes
                    workoutNotesField

                    if isReordering {
                        reorderList
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(sortedExercises) { we in
                                ExerciseInWorkoutView(workoutExercise: we)
                            }
                        }
                        .padding()
                    }

                    if !isReordering {
                        Button { showingExercisePicker = true } label: {
                            Label("Add Exercise", systemImage: "plus")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle(isEditingTitle ? "" : workout.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if isEditingTitle {
                        TextField("Workout title", text: $workout.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .submitLabel(.done)
                            .focused($titleFocused)
                            .onSubmit { isEditingTitle = false; titleFocused = false }
                            .frame(minWidth: 180)
                    } else {
                        Button {
                            isEditingTitle = true
                            titleFocused = true
                        } label: {
                            Text(workout.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text(elapsedString)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !isReordering {
                            Button {
                                withAnimation { showingNotes.toggle() }
                            } label: {
                                Image(systemName: workout.notes.isEmpty ? "note.text" : "note.text.badge.plus")
                                    .foregroundStyle(workout.notes.isEmpty ? .secondary : .accentColor)
                            }
                        }

                        if sortedExercises.count > 1 {
                            Button {
                                withAnimation { isReordering.toggle() }
                            } label: {
                                Image(systemName: isReordering ? "checkmark.circle.fill" : "arrow.up.arrow.down")
                                    .foregroundStyle(isReordering ? .green : .secondary)
                            }
                        }

                        if !isReordering {
                            Button("Finish") { showingFinishConfirm = true }
                                .fontWeight(.semibold)
                        }
                    }
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
                Button("Finish Workout") { finishWorkout() }
                Button("Cancel Workout", role: .destructive) { cancelWorkout() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You've completed \(workout.completedSetsCount) sets.")
            }
        }
        .onAppear {
            startTimer()
            RestTimerService.requestPermission()
            // Start Live Activity and register the complete-set closure
            appState.startLiveActivity(workout: workout)
            appState.completeNextSetAction = { [self] in completeNextSet() }
        }
        .onDisappear {
            timer?.invalidate()
            // Keep closure alive — workout sheet may re-appear
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                elapsedSeconds = Int(Date().timeIntervalSince(workout.startTime))
            }
        }
        // Update Live Activity whenever set completion state changes
        .onChange(of: workout.completedSetsCount) { _, _ in
            appState.updateLiveActivity(workout: workout)
        }
        .onChange(of: titleFocused) { _, focused in
            if !focused { isEditingTitle = false }
        }
    }

    // MARK: - Sorted exercises

    private var sortedExercises: [WorkoutExercise] {
        workout.exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }
    }

    // MARK: - Reorder list

    private var reorderList: some View {
        List {
            Section {
                ForEach(sortedExercises) { we in
                    HStack(spacing: 12) {
                        Image(systemName: "line.3.horizontal").foregroundStyle(.tertiary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(we.exercise?.name ?? "Exercise")
                                .font(.subheadline).fontWeight(.semibold)
                            Text("\(we.sets.count) set\(we.sets.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let sg = we.supersetGroup {
                            Text("SS\(sg)").font(.caption2).bold()
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onMove { indices, destination in
                    reorderExercises(from: indices, to: destination)
                }
            } header: {
                Text("Drag to reorder").font(.caption).foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        .frame(minHeight: CGFloat(sortedExercises.count) * 68 + 80)
    }

    // MARK: - Inline notes

    @ViewBuilder
    private var workoutNotesField: some View {
        if showingNotes {
            VStack(alignment: .leading, spacing: 6) {
                Label("Workout Notes", systemImage: "note.text")
                    .font(.caption).fontWeight(.semibold).foregroundStyle(.secondary)
                TextField("How's today's session going?", text: $workout.notes, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(3...8)
                    .padding(10)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .padding(.horizontal)
            .padding(.top, 10)
            .transition(.move(edge: .top).combined(with: .opacity))
        } else if !workout.notes.isEmpty {
            Button {
                withAnimation { showingNotes = true }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "note.text").font(.caption)
                    Text(workout.notes).font(.caption).lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down").font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers

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

    private func reorderExercises(from indices: IndexSet, to destination: Int) {
        var exercises = sortedExercises
        exercises.move(fromOffsets: indices, toOffset: destination)
        for (i, we) in exercises.enumerated() { we.exerciseOrder = i }
    }

    // MARK: - Complete next set (called from Live Activity deep link)

    func completeNextSet() {
        for we in sortedExercises {
            for set in we.sortedSets where !set.isCompleted {
                set.isCompleted = true
                try? modelContext.save()
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if autoStartRest { appState.startRestTimer(seconds: restSeconds) }
                appState.updateLiveActivity(workout: workout)
                return
            }
        }
    }

    // MARK: - Finish / cancel

    private func finishWorkout() {
        workout.endTime = Date()
        workout.isInProgress = false
        applyAutoProgression()
        try? modelContext.save()
        appState.endLiveActivity()
        showingComplete = true
    }

    private func applyAutoProgression() {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { $0.name == workout.title }
        )
        guard let routines = try? modelContext.fetch(descriptor),
              let routine = routines.first else { return }

        for we in workout.exercises {
            guard let exerciseID = we.exercise?.id,
                  let re = routine.exercises.first(where: { $0.exercise?.id == exerciseID }),
                  re.autoProgressEnabled else { continue }
            let parts = re.targetReps.components(separatedBy: "-")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
            let targetRepsTop = parts.last ?? 0
            guard targetRepsTop > 0 else { continue }
            let completedSets = we.sortedSets.filter { $0.isCompleted }
            let allHitTarget = !completedSets.isEmpty &&
                completedSets.allSatisfy { ($0.reps ?? 0) >= targetRepsTop }
            if allHitTarget {
                re.targetWeightKg = (re.targetWeightKg ?? 0) + re.autoProgressWeightKg
            }
        }
    }

    private func cancelWorkout() {
        appState.endLiveActivity()
        modelContext.delete(workout)
        try? modelContext.save()
        appState.endWorkout()
    }
}
