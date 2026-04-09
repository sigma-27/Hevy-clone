import XCTest
import SwiftData
@testable import IronLog

final class IronLogTests: XCTestCase {

    // MARK: - WeightConverter

    func testWeightConverterKg() {
        XCTAssertEqual(WeightConverter.toDisplay(100, useKg: true), 100)
        XCTAssertEqual(WeightConverter.fromDisplay(100, useKg: true), 100)
    }

    func testWeightConverterLbs() {
        XCTAssertEqual(WeightConverter.toDisplay(100, useKg: false), 220.462, accuracy: 0.001)
        XCTAssertEqual(WeightConverter.fromDisplay(220.462, useKg: false), 100, accuracy: 0.001)
    }

    func testWeightConverterRoundTrip() {
        let kg = 82.5
        let lbs = WeightConverter.toDisplay(kg, useKg: false)
        let backToKg = WeightConverter.fromDisplay(lbs, useKg: false)
        XCTAssertEqual(backToKg, kg, accuracy: 0.001)
    }

    func testWeightConverterFormatted() {
        XCTAssertEqual(WeightConverter.formatted(100, useKg: true), "100 kg")
        XCTAssertTrue(WeightConverter.formatted(100, useKg: false).contains("lbs"))
    }

    func testWeightConverterFormattedDecimal() {
        let result = WeightConverter.formatted(82.5, useKg: true)
        XCTAssertEqual(result, "82.5 kg")
    }

    func testWeightConverterUnitLabel() {
        XCTAssertEqual(WeightConverter.unitLabel(true), "kg")
        XCTAssertEqual(WeightConverter.unitLabel(false), "lbs")
    }

    // MARK: - OneRepMaxCalculator

    func testOneRepMaxEpley() {
        let orm = OneRepMaxCalculator.calculate(weightKg: 100, reps: 5, formula: .epley)
        XCTAssertEqual(orm, 116.67, accuracy: 0.1)
    }

    func testOneRepMaxBrzycki() {
        let orm = OneRepMaxCalculator.calculate(weightKg: 100, reps: 5, formula: .brzycki)
        XCTAssertEqual(orm, 112.5, accuracy: 0.1)
    }

    func testOneRepMaxLander() {
        let orm = OneRepMaxCalculator.calculate(weightKg: 100, reps: 5, formula: .lander)
        XCTAssertGreaterThan(orm, 110)
        XCTAssertLessThan(orm, 130)
    }

    func testOneRepMaxSingleRep() {
        XCTAssertEqual(OneRepMaxCalculator.calculate(weightKg: 150, reps: 1), 150)
    }

    func testOneRepMaxZeroReps() {
        XCTAssertEqual(OneRepMaxCalculator.calculate(weightKg: 100, reps: 0), 0)
    }

    func testOneRepMaxZeroWeight() {
        XCTAssertEqual(OneRepMaxCalculator.calculate(weightKg: 0, reps: 5), 0)
    }

    func testOneRepMaxFromSet() {
        let set = WorkoutSet(setNumber: 1, weightKg: 100, reps: 5)
        set.isCompleted = true
        let result = OneRepMaxCalculator.fromSet(set)
        XCTAssertNotNil(result)
        XCTAssertGreaterThan(result!, 100)
    }

    func testOneRepMaxFromSetIncomplete() {
        let set = WorkoutSet(setNumber: 1, weightKg: 100, reps: 5)
        set.isCompleted = false
        XCTAssertNil(OneRepMaxCalculator.fromSet(set))
    }

    func testOneRepMaxFromSetNoWeight() {
        let set = WorkoutSet(setNumber: 1, reps: 5)
        set.isCompleted = true
        XCTAssertNil(OneRepMaxCalculator.fromSet(set))
    }

    func testOneRepMaxAllFormulasIncreaseWithReps() {
        for formula in OneRepMaxCalculator.Formula.allCases {
            let low = OneRepMaxCalculator.calculate(weightKg: 100, reps: 3, formula: formula)
            let high = OneRepMaxCalculator.calculate(weightKg: 100, reps: 10, formula: formula)
            XCTAssertLessThan(low, high, "Formula \(formula.rawValue): fewer reps should yield lower 1RM")
        }
    }

    // MARK: - PlateCalculator

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

    func testPlateCalculatorBarOnly() {
        let result = PlateCalculator.calculate(targetKg: 20, barKg: 20, availablePlates: [5, 10, 20])
        XCTAssertEqual(result.actualWeight, 20, accuracy: 0.01)
        XCTAssertTrue(result.platesPerSide.isEmpty)
    }

    func testPlateCalculatorBelowBar() {
        // Target below bar weight — should return just the bar
        let result = PlateCalculator.calculate(targetKg: 10, barKg: 20, availablePlates: [5, 10])
        XCTAssertEqual(result.actualWeight, 20, accuracy: 0.01)
    }

    func testPlateCalculatorSymmetric() {
        // Result should always be symmetric (bar + 2× side weight)
        let result = PlateCalculator.calculate(
            targetKg: 140, barKg: 20,
            availablePlates: [1.25, 2.5, 5, 10, 20, 25]
        )
        let sideWeight = result.platesPerSide.reduce(0.0) { $0 + $1.weight * Double($1.count) }
        XCTAssertEqual(result.actualWeight, result.barWeight + sideWeight * 2, accuracy: 0.01)
    }

    // MARK: - Workout model

    func testWorkoutDuration() {
        let start = Date(timeIntervalSinceNow: -3600)
        let end = Date()
        let workout = Workout(startTime: start, endTime: end)
        XCTAssertEqual(workout.duration, 3600, accuracy: 1)
    }

    func testWorkoutDurationInProgress() {
        let workout = Workout(startTime: Date(timeIntervalSinceNow: -60))
        XCTAssertEqual(workout.duration, 60, accuracy: 2)
    }

    func testWorkoutCompletedSetsCount() {
        let workout = Workout()
        let we = WorkoutExercise(exerciseOrder: 0)
        let s1 = WorkoutSet(setNumber: 1); s1.isCompleted = true
        let s2 = WorkoutSet(setNumber: 2); s2.isCompleted = false
        let s3 = WorkoutSet(setNumber: 3); s3.isCompleted = true
        we.sets = [s1, s2, s3]
        workout.exercises = [we]
        XCTAssertEqual(workout.completedSetsCount, 2)
    }

    func testWorkoutTotalVolume() {
        let workout = Workout()
        let we = WorkoutExercise(exerciseOrder: 0)
        let s1 = WorkoutSet(setNumber: 1, weightKg: 100, reps: 5); s1.isCompleted = true
        let s2 = WorkoutSet(setNumber: 2, weightKg: 80, reps: 8); s2.isCompleted = true
        let s3 = WorkoutSet(setNumber: 3, weightKg: 60, reps: 10); s3.isCompleted = false  // not counted
        we.sets = [s1, s2, s3]
        workout.exercises = [we]
        // 100*5 + 80*8 = 500 + 640 = 1140
        XCTAssertEqual(workout.totalVolumeKg, 1140, accuracy: 0.01)
    }

    // MARK: - ExportService round-trip

    @MainActor
    func testExportImportRoundTrip() async throws {
        let schema = Schema([
            Exercise.self, Workout.self, WorkoutExercise.self, WorkoutSet.self,
            Routine.self, RoutineExercise.self, BodyWeightEntry.self,
            ProgressPhoto.self, UserSettings.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        // Seed a minimal exercise
        let exercise = Exercise(name: "Bench Press", category: "Strength",
                                primaryMuscles: ["chest"], secondaryMuscles: ["triceps"],
                                equipment: "barbell", instructions: "")
        context.insert(exercise)

        // Create a completed workout
        let workout = Workout(title: "Push Day", startTime: Date(timeIntervalSinceNow: -3600),
                              endTime: Date(), notes: "Test notes", isInProgress: false)
        let we = WorkoutExercise(exerciseOrder: 0)
        we.exercise = exercise
        we.workout = workout
        let set = WorkoutSet(setNumber: 1, weightKg: 80, reps: 8)
        set.isCompleted = true
        set.workoutExercise = we
        we.sets = [set]
        workout.exercises = [we]
        context.insert(set)
        context.insert(we)
        context.insert(workout)

        // Body weight entry
        context.insert(BodyWeightEntry(weightKg: 80, date: Date(), notes: "Morning"))
        try context.save()

        // Export
        let data = try await ExportService.exportJSON(modelContainer: container)
        XCTAssertFalse(data.isEmpty)

        // Verify JSON structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["version"] as? Int, 1)
        let workoutsJSON = json?["workouts"] as? [[String: Any]]
        XCTAssertEqual(workoutsJSON?.count, 1)
        XCTAssertEqual(workoutsJSON?.first?["title"] as? String, "Push Day")

        let bwJSON = json?["bodyWeightEntries"] as? [[String: Any]]
        XCTAssertEqual(bwJSON?.count, 1)

        // Import into a fresh container
        let config2 = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container2 = try ModelContainer(for: schema, configurations: [config2])
        let context2 = ModelContext(container2)

        // Need the exercise in the destination store for lookup
        let exercise2 = Exercise(name: "Bench Press", category: "Strength",
                                 primaryMuscles: ["chest"], secondaryMuscles: [],
                                 equipment: "barbell", instructions: "")
        context2.insert(exercise2)
        try context2.save()

        try await ExportService.importJSON(data, into: container2)

        // Verify import
        let importedWorkouts = try ModelContext(container2).fetch(FetchDescriptor<Workout>())
        XCTAssertEqual(importedWorkouts.count, 1)
        XCTAssertEqual(importedWorkouts.first?.title, "Push Day")
        XCTAssertEqual(importedWorkouts.first?.notes, "Test notes")

        let importedBW = try ModelContext(container2).fetch(FetchDescriptor<BodyWeightEntry>())
        XCTAssertEqual(importedBW.count, 1)
        XCTAssertEqual(importedBW.first?.weightKg, 80)
    }

    // MARK: - Auto-progression logic (pure logic, no SwiftData needed)

    func testAutoProgressionRepsRange() {
        // Parse "8-12" → top = 12
        let targetReps = "8-12"
        let parts = targetReps.components(separatedBy: "-")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        XCTAssertEqual(parts.last, 12)
        XCTAssertEqual(parts.first, 8)
    }

    func testAutoProgressionSingleRep() {
        let parts = "5".components(separatedBy: "-")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        XCTAssertEqual(parts.last, 5)
    }

    func testAutoProgressionAllHitTarget() {
        let completedSets = [
            makeSet(reps: 12, completed: true),
            makeSet(reps: 13, completed: true),
            makeSet(reps: 12, completed: true)
        ]
        let targetRepsTop = 12
        let allHit = !completedSets.isEmpty &&
            completedSets.allSatisfy { ($0.reps ?? 0) >= targetRepsTop }
        XCTAssertTrue(allHit)
    }

    func testAutoProgressionNotAllHitTarget() {
        let completedSets = [
            makeSet(reps: 12, completed: true),
            makeSet(reps: 10, completed: true),   // below target
            makeSet(reps: 12, completed: true)
        ]
        let targetRepsTop = 12
        let allHit = completedSets.allSatisfy { ($0.reps ?? 0) >= targetRepsTop }
        XCTAssertFalse(allHit)
    }

    func testAutoProgressionEmptySetsNoProgress() {
        let completedSets: [WorkoutSet] = []
        let targetRepsTop = 12
        let allHit = !completedSets.isEmpty &&
            completedSets.allSatisfy { ($0.reps ?? 0) >= targetRepsTop }
        XCTAssertFalse(allHit, "No completed sets should not trigger progression")
    }

    // MARK: - WorkoutSet model

    func testWorkoutSetDefaultType() {
        let set = WorkoutSet(setNumber: 1)
        XCTAssertEqual(set.setType, "normal")
    }

    func testWorkoutSetNotCompletedByDefault() {
        let set = WorkoutSet(setNumber: 1)
        XCTAssertFalse(set.isCompleted)
    }

    // MARK: - Helpers

    private func makeSet(reps: Int, completed: Bool) -> WorkoutSet {
        let s = WorkoutSet(setNumber: 1, weightKg: 80, reps: reps)
        s.isCompleted = completed
        return s
    }
}
