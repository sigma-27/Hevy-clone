import SwiftData
import Foundation

@Model
final class WorkoutExercise {
    @Attribute(.unique) var id: UUID
    var exerciseOrder: Int
    var notes: String
    var supersetGroup: Int?
    var workout: Workout?
    var exercise: Exercise?
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.workoutExercise)
    var sets: [WorkoutSet]

    var sortedSets: [WorkoutSet] {
        sets.sorted { $0.setNumber < $1.setNumber }
    }

    init(id: UUID = UUID(), exerciseOrder: Int, notes: String = "", supersetGroup: Int? = nil) {
        self.id = id
        self.exerciseOrder = exerciseOrder
        self.notes = notes
        self.supersetGroup = supersetGroup
        self.sets = []
    }
}
