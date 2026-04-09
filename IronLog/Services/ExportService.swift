import Foundation
import SwiftData

struct ExportService {
    // Codable DTOs for export
    struct ExportPackage: Codable {
        var version: Int = 1
        var exportedAt: Date
        var workouts: [WorkoutDTO]
        var routines: [RoutineDTO]
        var bodyWeightEntries: [BodyWeightDTO]
    }

    struct WorkoutDTO: Codable {
        var id: String
        var title: String
        var startTime: Date
        var endTime: Date?
        var notes: String
        var exercises: [WorkoutExerciseDTO]
    }

    struct WorkoutExerciseDTO: Codable {
        var id: String
        var exerciseOrder: Int
        var exerciseName: String
        var notes: String
        var supersetGroup: Int?
        var sets: [WorkoutSetDTO]
    }

    struct WorkoutSetDTO: Codable {
        var setNumber: Int
        var weightKg: Double?
        var reps: Int?
        var rpe: Double?
        var setType: String
        var isCompleted: Bool
    }

    struct RoutineDTO: Codable {
        var id: String
        var name: String
        var notes: String
        var scheduledDays: [Int]
        var exercises: [RoutineExerciseDTO]
    }

    struct RoutineExerciseDTO: Codable {
        var exerciseOrder: Int
        var exerciseName: String
        var targetSets: Int
        var targetReps: String
        var targetWeightKg: Double?
        var autoProgressEnabled: Bool
        var autoProgressWeightKg: Double
    }

    struct BodyWeightDTO: Codable {
        var weightKg: Double
        var date: Date
        var notes: String
    }

    static func exportJSON(modelContainer: ModelContainer) async throws -> Data {
        let context = ModelContext(modelContainer)
        let workouts = try context.fetch(FetchDescriptor<Workout>(
            predicate: #Predicate { !$0.isInProgress },
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        ))
        let routines = try context.fetch(FetchDescriptor<Routine>())
        let bwEntries = try context.fetch(FetchDescriptor<BodyWeightEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        ))

        let workoutDTOs = workouts.map { w -> WorkoutDTO in
            let exDTOs = w.exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }.map { we -> WorkoutExerciseDTO in
                let setDTOs = we.sortedSets.map { s in
                    WorkoutSetDTO(setNumber: s.setNumber, weightKg: s.weightKg, reps: s.reps,
                                  rpe: s.rpe, setType: s.setType, isCompleted: s.isCompleted)
                }
                return WorkoutExerciseDTO(id: we.id.uuidString, exerciseOrder: we.exerciseOrder,
                                          exerciseName: we.exercise?.name ?? "", notes: we.notes,
                                          supersetGroup: we.supersetGroup, sets: setDTOs)
            }
            return WorkoutDTO(id: w.id.uuidString, title: w.title, startTime: w.startTime,
                              endTime: w.endTime, notes: w.notes, exercises: exDTOs)
        }

        let routineDTOs = routines.map { r -> RoutineDTO in
            let exDTOs = r.sortedExercises.map { re in
                RoutineExerciseDTO(exerciseOrder: re.exerciseOrder, exerciseName: re.exercise?.name ?? "",
                                   targetSets: re.targetSets, targetReps: re.targetReps,
                                   targetWeightKg: re.targetWeightKg, autoProgressEnabled: re.autoProgressEnabled,
                                   autoProgressWeightKg: re.autoProgressWeightKg)
            }
            return RoutineDTO(id: r.id.uuidString, name: r.name, notes: r.notes,
                              scheduledDays: r.scheduledDays, exercises: exDTOs)
        }

        let bwDTOs = bwEntries.map { BodyWeightDTO(weightKg: $0.weightKg, date: $0.date, notes: $0.notes) }

        let pkg = ExportPackage(exportedAt: Date(), workouts: workoutDTOs,
                                routines: routineDTOs, bodyWeightEntries: bwDTOs)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(pkg)
    }
}
