import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var showingExercisePicker = false
    @State private var isEditing = false

    private let dayNames = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

    var body: some View {
        List {
            // Scheduled days
            Section("Scheduled Days") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            Button {
                                if routine.scheduledDays.contains(day) {
                                    routine.scheduledDays.removeAll { $0 == day }
                                } else {
                                    routine.scheduledDays.append(day)
                                }
                            } label: {
                                Text(dayNames[day])
                                    .font(.subheadline).fontWeight(.semibold)
                                    .frame(width: 44, height: 44)
                                    .background(routine.scheduledDays.contains(day) ? Color.accentColor : Color(.tertiarySystemBackground))
                                    .foregroundStyle(routine.scheduledDays.contains(day) ? .white : .primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Notes
            Section("Notes") {
                TextField("Routine notes", text: $routine.notes, axis: .vertical)
                    .font(.subheadline)
            }

            // Exercises
            Section {
                ForEach(routine.sortedExercises) { re in
                    routineExerciseRow(re)
                }
                .onMove { from, to in
                    var sorted = routine.sortedExercises
                    sorted.move(fromOffsets: from, toOffset: to)
                    for (i, re) in sorted.enumerated() { re.exerciseOrder = i }
                }
                .onDelete { offsets in
                    let sorted = routine.sortedExercises
                    for i in offsets { modelContext.delete(sorted[i]) }
                }
                Button { showingExercisePicker = true } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            } header: {
                HStack {
                    Text("Exercises")
                    Spacer()
                    EditButton()
                }
            }
        }
        .navigationTitle(routine.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Start") { startWorkout() }
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingExercisePicker) {
            ExercisePickerView { exercise in
                addExercise(exercise)
                showingExercisePicker = false
            }
        }
    }

    private func routineExerciseRow(_ re: RoutineExercise) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(re.exercise?.name ?? "Exercise")
                .font(.subheadline).fontWeight(.semibold)
            HStack(spacing: 16) {
                Label("\(re.targetSets) sets", systemImage: "number.circle")
                    .font(.caption).foregroundStyle(.secondary)
                Label(re.targetReps + " reps", systemImage: "arrow.up.arrow.down")
                    .font(.caption).foregroundStyle(.secondary)
                if re.autoProgressEnabled {
                    Label("+\(re.autoProgressWeightKg.formatted())kg", systemImage: "arrow.up.right")
                        .font(.caption).foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func addExercise(_ exercise: Exercise) {
        let re = RoutineExercise(exerciseOrder: routine.exercises.count)
        re.exercise = exercise
        re.routine = routine
        modelContext.insert(re)
        routine.exercises.append(re)
    }

    private func startWorkout() {
        let workout = Workout(title: routine.name)
        for (i, re) in routine.sortedExercises.enumerated() {
            let we = WorkoutExercise(exerciseOrder: i, supersetGroup: re.supersetGroup)
            we.exercise = re.exercise
            we.workout = workout
            for j in 0..<re.targetSets {
                let set = WorkoutSet(setNumber: j + 1, weightKg: re.targetWeightKg)
                we.sets.append(set)
                modelContext.insert(set)
            }
            workout.exercises.append(we)
            modelContext.insert(we)
        }
        routine.lastUsed = Date()
        modelContext.insert(workout)
        appState.startWorkout(workout)
    }
}
