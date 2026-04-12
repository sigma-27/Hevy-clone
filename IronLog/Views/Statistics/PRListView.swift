import SwiftUI
import SwiftData

struct PRListView: View {
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Query private var settings: [UserSettings]

    private var useKg: Bool { settings.first?.useKilograms ?? true }
    private var formula: OneRepMaxCalculator.Formula {
        OneRepMaxCalculator.Formula(rawValue: settings.first?.oneRMFormula ?? "Epley") ?? .epley
    }

    struct ExercisePR: Identifiable {
        let id: UUID
        let exercise: Exercise
        let bestWeightKg: Double
        let bestReps: Int
        let estimatedOneRM: Double
        let date: Date
    }

    private var prs: [ExercisePR] {
        exercises.compactMap { exercise in
            let sets = workouts
                .filter { !$0.isInProgress }
                .flatMap { $0.exercises }
                .filter { $0.exercise?.id == exercise.id }
                .flatMap { $0.sortedSets }
                .filter { $0.isCompleted }
            guard let best = sets.max(by: {
                let a = OneRepMaxCalculator.fromSet($0, formula: formula) ?? 0
                let b = OneRepMaxCalculator.fromSet($1, formula: formula) ?? 0
                return a < b
            }),
            let w = best.weightKg, let r = best.reps,
            let workout = best.workoutExercise?.workout
            else { return nil }
            return ExercisePR(
                id: exercise.id,
                exercise: exercise,
                bestWeightKg: w, bestReps: r,
                estimatedOneRM: OneRepMaxCalculator.calculate(weightKg: w, reps: r, formula: formula),
                date: workout.startTime
            )
        }
        .sorted { $0.estimatedOneRM > $1.estimatedOneRM }
    }

    var body: some View {
        Group {
            if prs.isEmpty {
                EmptyStateView(title: "No Records Yet", message: "Your personal records will appear here after your first workout.", systemImage: "trophy")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(prs) { pr in
                        NavigationLink(destination: ExerciseStatsView(exercise: pr.exercise)) {
                            prRow(pr)
                        }
                    }
                }
            }
        }
        .navigationTitle("Personal Records")
    }

    private func prRow(_ pr: ExercisePR) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(pr.exercise.name).font(.subheadline).fontWeight(.semibold)
                Text(pr.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(WeightConverter.toDisplay(pr.bestWeightKg, useKg: useKg))) \(WeightConverter.unitLabel(useKg)) × \(pr.bestReps)")
                    .font(.subheadline).fontWeight(.semibold)
                Text("1RM ~\(Int(WeightConverter.toDisplay(pr.estimatedOneRM, useKg: useKg))) \(WeightConverter.unitLabel(useKg))")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
