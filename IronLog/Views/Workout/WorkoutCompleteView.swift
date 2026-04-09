import SwiftUI
import SwiftData

struct WorkoutCompleteView: View {
    var workout: Workout
    var onDismiss: () -> Void = {}
    @Query private var settings: [UserSettings]
    @Query(sort: \Workout.startTime, order: .reverse) private var allWorkouts: [Workout]

    private var useKg: Bool { settings.first?.useKilograms ?? true }

    private var newPRExercises: [String] {
        // Find exercises where today's best 1RM exceeds historical best
        let formula = OneRepMaxCalculator.Formula(rawValue: settings.first?.oneRMFormula ?? "Epley") ?? .epley
        var prs: [String] = []
        for we in workout.exercises {
            guard let exerciseID = we.exercise?.id,
                  let exerciseName = we.exercise?.name else { continue }
            let todayBest = we.sortedSets
                .compactMap { OneRepMaxCalculator.fromSet($0, formula: formula) }
                .max() ?? 0
            guard todayBest > 0 else { continue }

            let historicalBest = allWorkouts
                .filter { !$0.isInProgress && $0.id != workout.id }
                .flatMap { $0.exercises }
                .filter { $0.exercise?.id == exerciseID }
                .flatMap { $0.sortedSets }
                .compactMap { OneRepMaxCalculator.fromSet($0, formula: formula) }
                .max() ?? 0

            if todayBest > historicalBest {
                prs.append(exerciseName)
            }
        }
        return prs
    }

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64)).foregroundStyle(.green)
            Text("Workout Complete!").font(.title2).fontWeight(.bold)

            statsGrid

            if !newPRExercises.isEmpty {
                prSection
            }

            Button("Done", action: onDismiss)
                .frame(maxWidth: .infinity).padding()
                .background(Color.accentColor).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
        }
        .padding()
    }

    private var statsGrid: some View {
        let mins = Int(workout.duration / 60)
        let durationStr = mins < 60 ? "\(mins)m" : "\(mins / 60)h \(mins % 60)m"
        let volume = workout.totalVolumeKg
        let displayVol = useKg ? volume : volume * 2.20462
        let volStr = String(format: "%.0f %@", displayVol, WeightConverter.unitLabel(useKg))

        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
            statCell(value: durationStr, label: "Duration", icon: "timer")
            statCell(value: "\(workout.completedSetsCount)", label: "Sets", icon: "number")
            statCell(value: volStr, label: "Volume", icon: "scalemass")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var prSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Personal Records", systemImage: "trophy.fill")
                .font(.headline).foregroundStyle(.orange)
            ForEach(newPRExercises, id: \.self) { name in
                HStack {
                    Image(systemName: "star.fill").foregroundStyle(.yellow).font(.caption)
                    Text(name).font(.subheadline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.2)))
    }

    private func statCell(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundStyle(.accentColor)
            Text(value).font(.headline).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
