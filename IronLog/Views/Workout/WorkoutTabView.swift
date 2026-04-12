import SwiftUI
import SwiftData

struct WorkoutTabView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query private var routines: [Routine]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active workout banner
                    if appState.showingActiveWorkout, let workout = appState.activeWorkout {
                        activeWorkoutBanner(workout: workout)
                    }

                    // Start empty workout
                    startSection

                    // Routines
                    if !routines.isEmpty {
                        routinesSection
                    }
                }
                .padding()
            }
            .navigationTitle("Workout")
        }
    }

    private func activeWorkoutBanner(workout: Workout) -> some View {
        Button { appState.showingActiveWorkout = true } label: {
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                VStack(alignment: .leading) {
                    Text("Workout in progress").font(.subheadline).fontWeight(.semibold)
                    Text(workout.title).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }

    private var startSection: some View {
        VStack(spacing: 12) {
            Text("Quick Start").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
            Button {
                let workout = Workout(title: "Workout \(Date().formatted(date: .abbreviated, time: .omitted))")
                modelContext.insert(workout)
                appState.startWorkout(workout)
            } label: {
                Label("Start Empty Workout", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Routines").font(.headline)
            ForEach(routines) { routine in
                NavigationLink(destination: RoutineDetailView(routine: routine)) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(routine.name).font(.subheadline).fontWeight(.semibold)
                            Text("\(routine.exercises.count) exercises")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            startWorkout(from: routine)
                        } label: {
                            Text("Start").font(.subheadline).padding(.horizontal, 14).padding(.vertical, 7)
                                .background(Color.accentColor).foregroundStyle(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func startWorkout(from routine: Routine) {
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
