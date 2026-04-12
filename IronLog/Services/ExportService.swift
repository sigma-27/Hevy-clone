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
        var durationSeconds: Int?
        var distanceMeters: Double?
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
        var supersetGroup: Int?
        var notes: String?          // optional for backwards-compatible import
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
                                  rpe: s.rpe, setType: s.setType, isCompleted: s.isCompleted,
                                  durationSeconds: s.durationSeconds, distanceMeters: s.distanceMeters)
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
                                   targetWeightKg: re.targetWeightKg, supersetGroup: re.supersetGroup,
                                   notes: re.notes, autoProgressEnabled: re.autoProgressEnabled,
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

    // MARK: - Import

    static func importJSON(_ data: Data, into modelContainer: ModelContainer) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let pkg = try decoder.decode(ExportPackage.self, from: data)

        let context = ModelContext(modelContainer)

        // Delete existing completed workouts, routines, body weight entries
        let existingWorkouts = try context.fetch(FetchDescriptor<Workout>())
        existingWorkouts.forEach { context.delete($0) }
        let existingRoutines = try context.fetch(FetchDescriptor<Routine>())
        existingRoutines.forEach { context.delete($0) }
        let existingBW = try context.fetch(FetchDescriptor<BodyWeightEntry>())
        existingBW.forEach { context.delete($0) }
        try context.save()

        // Build exercise lookup by name (case-insensitive)
        let allExercises = try context.fetch(FetchDescriptor<Exercise>())
        let exerciseByName = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.name.lowercased(), $0) })

        // Import workouts
        for wDTO in pkg.workouts {
            let workout = Workout(
                id: UUID(uuidString: wDTO.id) ?? UUID(),
                title: wDTO.title,
                startTime: wDTO.startTime,
                endTime: wDTO.endTime,
                notes: wDTO.notes,
                isInProgress: false
            )
            for (i, weDTO) in wDTO.exercises.enumerated() {
                let we = WorkoutExercise(
                    id: UUID(uuidString: weDTO.id) ?? UUID(),
                    exerciseOrder: weDTO.exerciseOrder == 0 && i > 0 ? i : weDTO.exerciseOrder,
                    notes: weDTO.notes,
                    supersetGroup: weDTO.supersetGroup
                )
                we.exercise = exerciseByName[weDTO.exerciseName.lowercased()]
                we.workout = workout
                for sDTO in weDTO.sets {
                    let set = WorkoutSet(
                        setNumber: sDTO.setNumber,
                        weightKg: sDTO.weightKg,
                        reps: sDTO.reps,
                        rpe: sDTO.rpe,
                        durationSeconds: sDTO.durationSeconds,
                        distanceMeters: sDTO.distanceMeters,
                        isCompleted: sDTO.isCompleted,
                        setType: sDTO.setType
                    )
                    set.workoutExercise = we
                    we.sets.append(set)
                    context.insert(set)
                }
                workout.exercises.append(we)
                context.insert(we)
            }
            context.insert(workout)
        }

        // Import routines
        for rDTO in pkg.routines {
            let routine = Routine(
                id: UUID(uuidString: rDTO.id) ?? UUID(),
                name: rDTO.name,
                notes: rDTO.notes,
                scheduledDays: rDTO.scheduledDays
            )
            for reDTO in rDTO.exercises {
                let re = RoutineExercise(
                    exerciseOrder: reDTO.exerciseOrder,
                    targetSets: reDTO.targetSets,
                    targetReps: reDTO.targetReps,
                    targetWeightKg: reDTO.targetWeightKg,
                    supersetGroup: reDTO.supersetGroup,
                    notes: reDTO.notes ?? "",
                    autoProgressEnabled: reDTO.autoProgressEnabled,
                    autoProgressWeightKg: reDTO.autoProgressWeightKg
                )
                re.exercise = exerciseByName[reDTO.exerciseName.lowercased()]
                re.routine = routine
                routine.exercises.append(re)
                context.insert(re)
            }
            context.insert(routine)
        }

        // Import body weight
        for bwDTO in pkg.bodyWeightEntries {
            context.insert(BodyWeightEntry(weightKg: bwDTO.weightKg, date: bwDTO.date, notes: bwDTO.notes))
        }

        try context.save()
    }
}
