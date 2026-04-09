import SwiftUI
import SwiftData
import Charts

struct ExerciseStatsView: View {
    var exercise: Exercise
    @Query private var allWorkouts: [Workout]
    @Query private var settings: [UserSettings]

    private var useKg: Bool { settings.first?.useKilograms ?? true }

    private struct SessionStat: Identifiable {
        let id = UUID()
        let date: Date
        let estimatedOneRM: Double
        let maxWeight: Double
        let volume: Double
    }

    private var sessionStats: [SessionStat] {
        let formula = OneRepMaxCalculator.Formula(rawValue: settings.first?.oneRMFormula ?? "Epley") ?? .epley
        return allWorkouts
            .filter { !$0.isInProgress }
            .compactMap { workout -> SessionStat? in
                let sets = workout.exercises
                    .filter { $0.exercise?.id == exercise.id }
                    .flatMap { $0.sortedSets }
                    .filter { $0.isCompleted }
                guard !sets.isEmpty else { return nil }
                let best = sets.max { a, b in
                    let a1 = OneRepMaxCalculator.fromSet(a, formula: formula) ?? 0
                    let b1 = OneRepMaxCalculator.fromSet(b, formula: formula) ?? 0
                    return a1 < b1
                }
                let orm = OneRepMaxCalculator.fromSet(best!, formula: formula) ?? 0
                let maxW = sets.compactMap(\.weightKg).max() ?? 0
                let vol = sets.compactMap { s -> Double? in
                    guard let w = s.weightKg, let r = s.reps else { return nil }
                    return w * Double(r)
                }.reduce(0, +)
                return SessionStat(date: workout.startTime, estimatedOneRM: orm, maxWeight: maxW, volume: vol)
            }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            if sessionStats.isEmpty {
                EmptyStateView(title: "No Data Yet", message: "Log this exercise to see your stats.", systemImage: "chart.line.uptrend.xyaxis")
                    .padding(.vertical, 32)
            } else {
                // 1RM chart
                Section("Estimated 1RM") {
                    Chart(sessionStats) { stat in
                        LineMark(x: .value("Date", stat.date), y: .value("1RM", useKg ? stat.estimatedOneRM : stat.estimatedOneRM * 2.20462))
                            .interpolationMethod(.catmullRom)
                        AreaMark(x: .value("Date", stat.date), y: .value("1RM", useKg ? stat.estimatedOneRM : stat.estimatedOneRM * 2.20462))
                            .foregroundStyle(Color.accentColor.opacity(0.1))
                            .interpolationMethod(.catmullRom)
                    }
                    .frame(height: 160)
                    .chartYAxisLabel(useKg ? "kg" : "lbs")
                }

                // Volume chart
                Section("Volume per Session") {
                    Chart(sessionStats) { stat in
                        BarMark(x: .value("Date", stat.date, unit: .day),
                                y: .value("Volume", useKg ? stat.volume : stat.volume * 2.20462))
                    }
                    .frame(height: 120)
                }

                // Bests
                if let best = sessionStats.max(by: { $0.estimatedOneRM < $1.estimatedOneRM }) {
                    Section("All-Time Bests") {
                        statRow("Est. 1RM", value: WeightConverter.formatted(best.estimatedOneRM, useKg: useKg))
                        statRow("Max Weight", value: WeightConverter.formatted(best.maxWeight, useKg: useKg))
                        statRow("Sessions", value: "\(sessionStats.count)")
                    }
                }
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}
