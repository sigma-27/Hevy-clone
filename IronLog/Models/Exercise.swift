import SwiftData
import Foundation

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    var equipment: String
    var instructions: String
    var isCustom: Bool
    var createdAt: Date
    @Relationship(deleteRule: .nullify) var workoutExercises: [WorkoutExercise]
    @Relationship(deleteRule: .nullify) var routineExercises: [RoutineExercise]

    init(
        id: UUID = UUID(), name: String, category: String = "Strength",
        primaryMuscles: [String] = [], secondaryMuscles: [String] = [],
        equipment: String = "barbell", instructions: String = "",
        isCustom: Bool = false, createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.primaryMuscles = primaryMuscles
        self.secondaryMuscles = secondaryMuscles
        self.equipment = equipment
        self.instructions = instructions
        self.isCustom = isCustom
        self.createdAt = createdAt
        self.workoutExercises = []
        self.routineExercises = []
    }
}
