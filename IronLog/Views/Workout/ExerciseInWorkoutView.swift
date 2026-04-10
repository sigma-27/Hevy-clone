import SwiftUI
import SwiftData

struct ExerciseInWorkoutView: View {
    @Bindable var workoutExercise: WorkoutExercise
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query(sort: \Workout.startTime, order: .reverse) private var allWorkouts: [Workout]
    @State private var showingNotes = false
    @State private var showingSupersetPicker = false

    private var useKg: Bool { settings.first?.useKilograms ?? true }
    private var restSeconds: TimeInterval { Double(settings.first?.restTimerDefaultSeconds ?? 90) }
    private var autoStart: Bool { settings.first?.autoStartRestTimer ?? true }
    private var showRPE: Bool { settings.first?.showRPE ?? true }
    private var isCardio: Bool { workoutExercise.exercise?.category == "Cardio" }

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

    /// Other exercises in the same workout available for superset linking
    private var otherExercises: [WorkoutExercise] {
        workoutExercise.workout?.exercises
            .filter { $0.id != workoutExercise.id }
            .sorted { $0.exerciseOrder < $1.exerciseOrder }
            ?? []
    }

    private static let supersetColors: [Color] = [.orange, .purple, .teal, .pink, .indigo]
    private var supersetColor: Color {
        guard let g = workoutExercise.supersetGroup else { return .orange }
        return Self.supersetColors[(g - 1) % Self.supersetColors.count]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Superset accent bar
            if workoutExercise.supersetGroup != nil {
                supersetColor
                    .frame(height: 3)
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
            }

            // Header row
            HStack {
                if let sg = workoutExercise.supersetGroup {
                    Text("SS\(sg)").font(.caption2).bold()
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(supersetColor.opacity(0.2)).foregroundStyle(supersetColor)
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

                    if workoutExercise.supersetGroup == nil {
                        Button { showingSupersetPicker = true } label: {
                            Label("Link as Superset", systemImage: "link")
                        }
                    } else {
                        Button { unlinkSuperset() } label: {
                            Label("Remove from Superset", systemImage: "link.badge.minus")
                        }
                    }

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

            // Column headers — dynamic based on exercise type
            HStack(spacing: 0) {
                Text("SET").frame(width: 44)
                Text("PREV").frame(maxWidth: .infinity)
                if isCardio {
                    Text("MIN:SS").frame(width: 70)
                    Text(useKg ? "KM" : "MI").frame(width: 56)
                } else {
                    Text(useKg ? "KG" : "LBS").frame(width: 70)
                    Text("REPS").frame(width: 56)
                    if showRPE { Text("RPE").frame(width: 36) }
                }
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
                    previousDurationSeconds: prevSet?.durationSeconds,
                    previousDistanceMeters: prevSet?.distanceMeters,
                    showRPE: showRPE,
                    isCardio: isCardio,
                    onCompleted: {
                        if autoStart { appState.startRestTimer(seconds: restSeconds) }
                    },
                    onDelete: { deleteSet(set) }
                )
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
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    workoutExercise.supersetGroup != nil ? supersetColor.opacity(0.4) : .clear,
                    lineWidth: 1.5
                )
        )
        .sheet(isPresented: $showingSupersetPicker) {
            supersetPickerSheet
        }
    }

    // MARK: - Superset Picker Sheet

    private var supersetPickerSheet: some View {
        NavigationStack {
            List {
                if otherExercises.isEmpty {
                    ContentUnavailableView(
                        "No Other Exercises",
                        systemImage: "link",
                        description: Text("Add more exercises to link as a superset.")
                    )
                } else {
                    Section("Choose exercise to pair with") {
                        ForEach(otherExercises) { other in
                            Button {
                                linkSuperset(with: other)
                                showingSupersetPicker = false
                            } label: {
                                HStack {
                                    if let sg = other.supersetGroup {
                                        Text("SS\(sg)").font(.caption2).bold()
                                            .padding(.horizontal, 5).padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.2))
                                            .foregroundStyle(.orange)
                                            .clipShape(Capsule())
                                    }
                                    Text(other.exercise?.name ?? "Exercise")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "link").foregroundStyle(.accentColor).font(.caption)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Link as Superset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingSupersetPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Actions

    private func linkSuperset(with other: WorkoutExercise) {
        let existing = workoutExercise.supersetGroup ?? other.supersetGroup
        if let group = existing {
            workoutExercise.supersetGroup = group
            other.supersetGroup = group
        } else {
            let used = workoutExercise.workout?.exercises.compactMap(\.supersetGroup) ?? []
            let next = (used.max() ?? 0) + 1
            workoutExercise.supersetGroup = next
            other.supersetGroup = next
        }
    }

    private func unlinkSuperset() {
        workoutExercise.supersetGroup = nil
    }

    private func addSet() {
        let nextNum = (workoutExercise.sets.map(\.setNumber).max() ?? 0) + 1
        let prev = workoutExercise.sortedSets.last
        let newSet: WorkoutSet
        if isCardio {
            newSet = WorkoutSet(
                setNumber: nextNum,
                durationSeconds: prev?.durationSeconds,
                distanceMeters: prev?.distanceMeters
            )
        } else {
            newSet = WorkoutSet(setNumber: nextNum, weightKg: prev?.weightKg, reps: prev?.reps)
        }
        newSet.workoutExercise = workoutExercise
        modelContext.insert(newSet)
        workoutExercise.sets.append(newSet)
    }

    private func deleteSet(_ set: WorkoutSet) {
        workoutExercise.sets.removeAll { $0.id == set.id }
        modelContext.delete(set)
        for (i, s) in workoutExercise.sortedSets.enumerated() {
            s.setNumber = i + 1
        }
    }

    private func deleteExercise() {
        if let workout = workoutExercise.workout {
            workout.exercises.removeAll { $0.id == workoutExercise.id }
        }
        modelContext.delete(workoutExercise)
    }
}
