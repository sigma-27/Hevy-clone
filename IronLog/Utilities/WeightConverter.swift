import Foundation

struct WeightConverter {
    static let kgToLbs: Double = 2.20462
    static let lbsToKg: Double = 0.453592

    static func toDisplay(_ kg: Double, useKg: Bool) -> Double {
        useKg ? kg : kg * kgToLbs
    }

    static func fromDisplay(_ value: Double, useKg: Bool) -> Double {
        useKg ? value : value * lbsToKg
    }

    static func unitLabel(_ useKg: Bool) -> String {
        useKg ? "kg" : "lbs"
    }

    static func formatted(_ kg: Double, useKg: Bool, decimals: Int = 1) -> String {
        let value = toDisplay(kg, useKg: useKg)
        let label = unitLabel(useKg)
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value)) \(label)"
        }
        return String(format: "%.\(decimals)f \(label)", value)
    }
}
