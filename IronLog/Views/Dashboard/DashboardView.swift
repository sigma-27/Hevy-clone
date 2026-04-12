import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Query private var routines: [Routine]

    private var completedWorkouts: [Workout] { workouts.filter { !$0.isInProgress } }

    private var todaysRoutines: [Routine] {
        // Calendar.weekday: 1=Sun … 7=Sat  →  scheduledDays: 0=Sun … 6=Sat
        let weekday = Calendar.current.component(.weekday, from: Date()) - 1
        return routines.filter { $0.scheduledDays.contains(weekday) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quick start card
                    quickStartCard

                    // Today's scheduled routines
                    if !todaysRoutines.isEmpty {
                        todaysPlanSection
                    }

                    // Recent workouts
                    if !completedWorkouts.isEmpty {
                        recentWorkoutsSection
                    } else if todaysRoutines.isEmpty {
                        EmptyStateView(
                            title: "No workouts yet",
                            message: "Start your first workout to see it here",
                            systemImage: "flame"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    // MARK: - Quick start

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready to train?")
                .font(.headline)
            Button {
                startEmptyWorkout()
            } label: {
                Label("Start Empty Workout", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Today's plan

    private var todaysPlanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Plan", systemImage: "calendar")
                .font(.headline)
            ForEach(todaysRoutines) { routine in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.name)
                            .font(.subheadline).fontWeight(.semibold)
                        Text("\(routine.exercises.count) exercise\(routine.exercises.count == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button {
                        startRoutineWorkout(routine)
                    } label: {
                        Text("Start")
                            .font(.subheadline).fontWeight(.semibold)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Recent workouts

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
            ForEach(completedWorkouts.prefix(5)) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutRowView(workout: workout)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func startEmptyWorkout() {
        let workout = Workout(title: "Workout \(Date().formatted(date: .abbreviated, time: .omitted))")
        modelContext.insert(workout)
        appState.startWorkout(workout)
    }

    private func startRoutineWorkout(_ routine: Routine) {
        let workout = Workout(title: routine.name)
        for (i, re) in routine.sortedExercises.enumerated() {
            let we = WorkoutExercise(exerciseOrder: i, supersetGroup: re.supersetGroup)
            we.exercise = re.exercise
            we.workout = workout
            // Parse lower bound of target reps range (e.g. "8-12" → 8, "10" → 10)
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

// MARK: - Workout row

private struct WorkoutRowView: View {
    var workout: Workout
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title).font(.subheadline).fontWeight(.semibold)
                Text(workout.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(durationString).font(.caption).foregroundStyle(.secondary)
                Text("\(workout.completedSetsCount) sets").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var durationString: String {
        let mins = Int(workout.duration / 60)
        return mins < 60 ? "\(mins)m" : "\(mins / 60)h \(mins % 60)m"
    }
}
