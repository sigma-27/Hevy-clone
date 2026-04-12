import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    @Bindable var routine: Routine
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @State private var showingExercisePicker = false
    @State private var editingExercise: RoutineExercise?

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
                    Button { editingExercise = re } label: {
                        routineExerciseRow(re)
                    }
                    .buttonStyle(.plain)
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
        .sheet(item: $editingExercise) { re in
            RoutineExerciseEditSheet(routineExercise: re)
        }
    }

    private func routineExerciseRow(_ re: RoutineExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(re.exercise?.name ?? "Exercise")
                    .font(.subheadline).fontWeight(.semibold)
                HStack(spacing: 16) {
                    Label("\(re.targetSets) sets", systemImage: "number.circle")
                        .font(.caption).foregroundStyle(.secondary)
                    Label(re.targetReps + " reps", systemImage: "arrow.up.arrow.down")
                        .font(.caption).foregroundStyle(.secondary)
                    if let w = re.targetWeightKg, w > 0 {
                        Label(String(format: "%.1f kg", w), systemImage: "scalemass")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if re.autoProgressEnabled {
                        Label("+\(re.autoProgressWeightKg.formatted())kg", systemImage: "arrow.up.right")
                            .font(.caption).foregroundStyle(.green)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func addExercise(_ exercise: Exercise) {
        let re = RoutineExercise(exerciseOrder: routine.exercises.count)
        re.exercise = exercise
        re.routine = routine
        modelContext.insert(re)
        routine.exercises.append(re)
        // Open editor immediately after adding
        editingExercise = re
    }

    private func startWorkout() {
        let workout = Workout(title: routine.name)
        for (i, re) in routine.sortedExercises.enumerated() {
            let we = WorkoutExercise(exerciseOrder: i, supersetGroup: re.supersetGroup)
            we.exercise = re.exercise
            we.workout = workout
            let targetReps = re.targetReps
                .split(separator: "-")
                .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                .first
            for j in 0..<re.targetSets {
                let set = WorkoutSet(setNumber: j + 1, weightKg: re.targetWeightKg, reps: targetReps)
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

// MARK: - Per-exercise edit sheet

struct RoutineExerciseEditSheet: View {
    @Bindable var routineExercise: RoutineExercise
    @Query private var settings: [UserSettings]
    @Environment(\.dismiss) private var dismiss
    @State private var weightString = ""

    private var useKg: Bool { settings.first?.useKilograms ?? true }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sets & Reps") {
                    Stepper("Sets: \(routineExercise.targetSets)",
                            value: $routineExercise.targetSets, in: 1...20)
                    HStack {
                        Text("Target Reps")
                        Spacer()
                        TextField("e.g. 8-12", text: $routineExercise.targetReps)
                            .keyboardType(.numbersAndPunctuation)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                Section("Target Weight (\(useKg ? "kg" : "lbs"))") {
                    TextField("Optional", text: $weightString)
                        .keyboardType(.decimalPad)
                        .onChange(of: weightString) { _, v in
                            if let w = Double(v.replacingOccurrences(of: ",", with: ".")) {
                                routineExercise.targetWeightKg = useKg ? w : w * 0.453592
                            } else if v.isEmpty {
                                routineExercise.targetWeightKg = nil
                            }
                        }
                }

                Section {
                    Toggle("Auto-Progression", isOn: $routineExercise.autoProgressEnabled)
                    if routineExercise.autoProgressEnabled {
                        Stepper(
                            "Add \(routineExercise.autoProgressWeightKg.formatted()) \(useKg ? "kg" : "lbs") per session",
                            value: $routineExercise.autoProgressWeightKg,
                            in: 0.5...10, step: 0.5
                        )
                    }
                } header: {
                    Text("Progression")
                } footer: {
                    if routineExercise.autoProgressEnabled {
                        Text("Weight increases automatically when all sets hit the top of your rep range.")
                    }
                }

                Section("Exercise Notes") {
                    TextField("Notes for this exercise", text: $routineExercise.notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle(routineExercise.exercise?.name ?? "Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
            .onAppear { syncWeightString() }
            .onChange(of: useKg) { _, _ in syncWeightString() }
        }
    }

    private func syncWeightString() {
        guard let w = routineExercise.targetWeightKg else { weightString = ""; return }
        let display = useKg ? w : w * 2.20462
        weightString = display.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(display))" : String(format: "%.1f", display)
    }
}
