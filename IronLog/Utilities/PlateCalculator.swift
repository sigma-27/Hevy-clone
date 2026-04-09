import Foundation

struct PlateCalculator {
    struct Result {
        let platesPerSide: [(weight: Double, count: Int)]
        let actualWeight: Double
        let barWeight: Double
    }

    static func calculate(targetKg: Double, barKg: Double, availablePlates: [Double]) -> Result {
        let sorted = availablePlates.sorted(by: >)
        var remaining = max(0, (targetKg - barKg) / 2)
        var plates: [(Double, Int)] = []
        for plate in sorted {
            if plate <= remaining + 0.001 {
                let count = Int(remaining / plate)
                if count > 0 {
                    plates.append((plate, count))
                    remaining -= plate * Double(count)
                }
            }
        }
        let sideWeight = plates.reduce(0.0) { $0 + $1.0 * Double($1.1) }
        return Result(platesPerSide: plates, actualWeight: barKg + sideWeight * 2, barWeight: barKg)
    }
}
