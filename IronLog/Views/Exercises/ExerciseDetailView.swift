import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    var exercise: Exercise
    @Query private var allWorkouts: [Workout]

    private var history: [WorkoutSet] {
        allWorkouts
            .filter { !$0.isInProgress }
            .flatMap { $0.exercises }
            .filter { $0.exercise?.id == exercise.id }
            .flatMap { $0.sortedSets }
            .filter { $0.isCompleted }
    }

    private var bestSet: WorkoutSet? {
        history.max { ($0.weightKg ?? 0) < ($1.weightKg ?? 0) }
    }

    var body: some View {
        List {
            // Muscle diagram
            if !exercise.primaryMuscles.isEmpty || !exercise.secondaryMuscles.isEmpty {
                Section("Muscles") {
                    MuscleDiagramView(
                        primaryMuscles: exercise.primaryMuscles,
                        secondaryMuscles: exercise.secondaryMuscles
                    )
                    .padding(.vertical, 8)

                    if !exercise.primaryMuscles.isEmpty {
                        HStack(alignment: .top) {
                            Text("Primary").font(.caption).foregroundStyle(.secondary).frame(width: 72, alignment: .leading)
                            FlowLayout(spacing: 6) {
                                ForEach(exercise.primaryMuscles, id: \.self) {
                                    MuscleGroupBadge(muscle: $0, isPrimary: true)
                                }
                            }
                        }
                    }
                    if !exercise.secondaryMuscles.isEmpty {
                        HStack(alignment: .top) {
                            Text("Secondary").font(.caption).foregroundStyle(.secondary).frame(width: 72, alignment: .leading)
                            FlowLayout(spacing: 6) {
                                ForEach(exercise.secondaryMuscles, id: \.self) {
                                    MuscleGroupBadge(muscle: $0, isPrimary: false)
                                }
                            }
                        }
                    }
                }
            }

            // Equipment
            Section("Equipment") {
                Label(exercise.equipment.capitalized, systemImage: "dumbbell.fill")
            }

            // Personal best
            if let best = bestSet {
                Section("Personal Best") {
                    HStack {
                        Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                        Text("\(Int(best.weightKg ?? 0)) kg × \(best.reps ?? 0) reps")
                            .font(.headline)
                        Spacer()
                        Text(OneRepMaxCalculator.calculate(weightKg: best.weightKg ?? 0, reps: best.reps ?? 1).formatted(.number.precision(.fractionLength(1))) + " kg est. 1RM")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }

            // Instructions
            if !exercise.instructions.isEmpty {
                Section("Instructions") {
                    Text(exercise.instructions)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // History snippet
            if !history.isEmpty {
                Section("Recent Sets") {
                    ForEach(history.suffix(10).reversed()) { set in
                        HStack {
                            Text(set.workoutExercise?.workout?.startTime.formatted(date: .abbreviated, time: .omitted) ?? "")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            if let w = set.weightKg, let r = set.reps {
                                Text("\(Int(w)) kg × \(r)").font(.subheadline)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !history.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: ExerciseStatsView(exercise: exercise)) {
                        Label("Statistics", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
        }
    }
}

// Simple flow layout for badges
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0 }
            .reduce(0) { $0 + $1 + spacing } - spacing
        return CGSize(width: proposal.width ?? 0, height: max(0, height))
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            for sub in row {
                let size = sub.sizeThatFits(.unspecified)
                sub.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += rowHeight + spacing
        }
    }
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubviews.Element]] {
        var rows: [[LayoutSubviews.Element]] = [[]]
        var x: CGFloat = 0
        let maxW = proposal.width ?? .infinity
        for sub in subviews {
            let w = sub.sizeThatFits(.unspecified).width
            if x + w > maxW, !rows[rows.count - 1].isEmpty { rows.append([]); x = 0 }
            rows[rows.count - 1].append(sub)
            x += w + spacing
        }
        return rows
    }
}
