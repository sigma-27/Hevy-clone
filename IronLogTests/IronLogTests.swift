import XCTest
@testable import IronLog

final class IronLogTests: XCTestCase {

    func testWeightConverterKg() {
        XCTAssertEqual(WeightConverter.toDisplay(100, useKg: true), 100)
        XCTAssertEqual(WeightConverter.fromDisplay(100, useKg: true), 100)
    }

    func testWeightConverterLbs() {
        XCTAssertEqual(WeightConverter.toDisplay(100, useKg: false), 220.462, accuracy: 0.001)
        XCTAssertEqual(WeightConverter.fromDisplay(220.462, useKg: false), 100, accuracy: 0.001)
    }

    func testOneRepMaxEpley() {
        let orm = OneRepMaxCalculator.calculate(weightKg: 100, reps: 5, formula: .epley)
        XCTAssertEqual(orm, 116.67, accuracy: 0.1)
    }

    func testOneRepMaxBrzycki() {
        let orm = OneRepMaxCalculator.calculate(weightKg: 100, reps: 5, formula: .brzycki)
        XCTAssertEqual(orm, 112.5, accuracy: 0.1)
    }

    func testOneRepMaxSingleRep() {
        let orm = OneRepMaxCalculator.calculate(weightKg: 150, reps: 1)
        XCTAssertEqual(orm, 150)
    }

    func testPlateCalculatorExact() {
        let result = PlateCalculator.calculate(
            targetKg: 100, barKg: 20,
            availablePlates: [1.25, 2.5, 5, 10, 20, 25]
        )
        XCTAssertEqual(result.actualWeight, 100, accuracy: 0.01)
    }

    func testPlateCalculatorApprox() {
        let result = PlateCalculator.calculate(
            targetKg: 85, barKg: 20,
            availablePlates: [5, 10, 20]
        )
        XCTAssertLessThanOrEqual(result.actualWeight, 85 + 5)
    }

    func testWeightConverterFormatted() {
        let label = WeightConverter.formatted(100, useKg: true)
        XCTAssertEqual(label, "100 kg")
        let lbsLabel = WeightConverter.formatted(100, useKg: false)
        XCTAssertTrue(lbsLabel.contains("lbs"))
    }
}
