import SwiftUI
import SwiftData

struct WorkoutDetailView: View {
    @Bindable var workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var settings: [UserSettings]
    @State private var isEditing = false

    private var useKg: Bool { settings.first?.useKilograms ?? true }

    var body: some View {
        List {
            // Stats header
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    statCell(volumeLabel, label: "Volume")
                    statCell(durationLabel, label: "Duration")
                    statCell("\(workout.completedSetsCount)", label: "Sets")
                }
                .padding(.vertical, 4)
            }

            // Title (editable in edit mode)
            if isEditing {
                Section("Title") {
                    TextField("Workout title", text: $workout.title)
                        .font(.subheadline)
                }
            }

            // Notes (editable in edit mode)
            if isEditing || !workout.notes.isEmpty {
                Section("Notes") {
                    if isEditing {
                        TextField("Workout notes", text: $workout.notes, axis: .vertical)
                            .font(.subheadline).lineLimit(2...6)
                    } else {
                        Text(workout.notes).font(.subheadline)
                    }
                }
            }

            // Exercises
            ForEach(workout.exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }) { we in
                let isCardio = we.exercise?.category == "Cardio"
                Section {
                    // Exercise notes (read-only)
                    if !we.notes.isEmpty {
                        Text(we.notes)
                            .font(.caption).foregroundStyle(.secondary)
                            .listRowBackground(Color.clear)
                    }
                    ForEach(we.sortedSets) { set in
                        CompletedSetRow(
                            set: set,
                            useKg: useKg,
                            isCardio: isCardio,
                            isEditing: isEditing
                        )
                    }
                } header: {
                    Text(we.exercise?.name ?? "Exercise")
                }
            }
        }
        .navigationTitle(workout.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 16) {
                    if isEditing {
                        Button("Done") {
                            try? modelContext.save()
                            isEditing = false
                        }
                        .fontWeight(.semibold)
                    } else {
                        Button("Edit") { isEditing = true }
                        Button("Redo") { redoWorkout() }
                    }
                }
            }
        }
    }

    private var volumeLabel: String {
        let vol = useKg ? workout.totalVolumeKg : workout.totalVolumeKg * 2.20462
        return String(format: "%.0f %@", vol, useKg ? "kg" : "lbs")
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
            let sortedSets = we.sortedSets
            let setCount = max(1, sortedSets.count)
            for j in 0..<setCount {
                // Use the matching set by index (not always the first set)
                let refSet = j < sortedSets.count ? sortedSets[j] : sortedSets.last
                let newSet = WorkoutSet(
                    setNumber: j + 1,
                    weightKg: refSet?.weightKg,
                    reps: refSet?.reps,
                    durationSeconds: refSet?.durationSeconds,
                    distanceMeters: refSet?.distanceMeters
                )
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

// MARK: - Editable set row

private struct CompletedSetRow: View {
    @Bindable var set: WorkoutSet
    var useKg: Bool
    var isCardio: Bool
    var isEditing: Bool

    @State private var weightString = ""
    @State private var repsString = ""
    @State private var durationString = ""
    @State private var distanceString = ""

    var body: some View {
        HStack {
            setLabel
                .frame(width: 52, alignment: .leading)
            Spacer()
            if isEditing {
                editFields
            } else {
                displayFields
            }
        }
        .onAppear { syncStrings() }
        .onChange(of: isEditing) { _, _ in syncStrings() }
    }

    @ViewBuilder
    private var setLabel: some View {
        switch set.setType {
        case "warmup":
            Text("W").font(.caption2).bold().foregroundStyle(.orange)
                .frame(width: 22, height: 22)
                .background(Color.orange.opacity(0.15)).clipShape(Circle())
        case "dropset":
            Text("D").font(.caption2).bold().foregroundStyle(.purple)
                .frame(width: 22, height: 22)
                .background(Color.purple.opacity(0.15)).clipShape(Circle())
        case "failure":
            Text("F").font(.caption2).bold().foregroundStyle(.red)
                .frame(width: 22, height: 22)
                .background(Color.red.opacity(0.15)).clipShape(Circle())
        default:
            Text("Set \(set.setNumber)").font(.subheadline).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var displayFields: some View {
        if isCardio {
            if let d = set.durationSeconds {
                Text(formatDuration(d))
                    .font(.subheadline).fontWeight(.semibold)
            }
            if let dist = set.distanceMeters {
                let display = useKg ? dist / 1000 : dist / 1609.344
                Text(String(format: "%.2f %@", display, useKg ? "km" : "mi"))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
        } else {
            if let w = set.weightKg {
                let display = useKg ? w : w * 2.20462
                let wStr = display.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(display))" : String(format: "%.1f", display)
                Text("\(wStr) \(useKg ? "kg" : "lbs")")
                    .font(.subheadline).fontWeight(.semibold)
            }
            if let r = set.reps {
                Text("× \(r)")
                    .font(.subheadline).fontWeight(.semibold)
            }
            if let rpe = set.rpe {
                Text("RPE \(rpe.formatted(.number.precision(.fractionLength(1))))")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var editFields: some View {
        if isCardio {
            HStack(spacing: 6) {
                TextField("0:00", text: $durationString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: durationString) { _, v in set.durationSeconds = parseDuration(v) }
                Text("·").foregroundStyle(.secondary)
                TextField("0.0", text: $distanceString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: distanceString) { _, v in
                        if let d = Double(v.replacingOccurrences(of: ",", with: ".")) {
                            set.distanceMeters = useKg ? d * 1000 : d * 1609.344
                        } else if v.isEmpty {
                            set.distanceMeters = nil
                        }
                    }
                Text(useKg ? "km" : "mi").font(.caption).foregroundStyle(.secondary)
            }
        } else {
            HStack(spacing: 6) {
                TextField("0", text: $weightString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: weightString) { _, v in
                        if let w = Double(v.replacingOccurrences(of: ",", with: ".")) {
                            set.weightKg = useKg ? w : w * 0.453592
                        } else if v.isEmpty {
                            set.weightKg = nil
                        }
                    }
                Text(useKg ? "kg" : "lbs").font(.caption).foregroundStyle(.secondary)
                Text("×").foregroundStyle(.secondary)
                TextField("0", text: $repsString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 40)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: repsString) { _, v in set.reps = Int(v) }
                Text("reps").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private func syncStrings() {
        if isCardio {
            durationString = set.durationSeconds.map { formatDuration($0) } ?? ""
            if let d = set.distanceMeters {
                distanceString = String(format: "%.2f", useKg ? d / 1000 : d / 1609.344)
            } else {
                distanceString = ""
            }
        } else {
            if let w = set.weightKg {
                let display = useKg ? w : w * 2.20462
                weightString = display.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(display))" : String(format: "%.1f", display)
            } else {
                weightString = ""
            }
            repsString = set.reps.map { "\($0)" } ?? ""
        }
    }

    private func parseDuration(_ raw: String) -> Int? {
        let parts = raw.split(separator: ":").map { Int($0) }
        if parts.count == 2, let m = parts[0], let s = parts[1] { return m * 60 + s }
        return Int(raw)
    }

    private func formatDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
