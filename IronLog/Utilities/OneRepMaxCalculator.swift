import Foundation

struct OneRepMaxCalculator {
    enum Formula: String, CaseIterable {
        case epley = "Epley"
        case brzycki = "Brzycki"
        case lander = "Lander"
    }

    static func calculate(weightKg: Double, reps: Int, formula: Formula = .epley) -> Double {
        guard reps > 0, weightKg > 0 else { return 0 }
        if reps == 1 { return weightKg }
        let r = Double(reps)
        switch formula {
        case .epley:   return weightKg * (1 + r / 30)
        case .brzycki: return reps < 37 ? weightKg * (36 / (37 - r)) : weightKg
        case .lander:  return (100 * weightKg) / (101.3 - 2.67123 * r)
        }
    }

    static func fromSet(_ set: WorkoutSet, formula: Formula = .epley) -> Double? {
        guard let w = set.weightKg, let r = set.reps, set.isCompleted, r > 0 else { return nil }
        return calculate(weightKg: w, reps: r, formula: formula)
    }
}
