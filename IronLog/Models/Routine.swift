import SwiftData
import Foundation

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var notes: String
    var createdAt: Date
    var lastUsed: Date?
    var scheduledDays: [Int]   // 0=Sun … 6=Sat
    @Relationship(deleteRule: .cascade, inverse: \RoutineExercise.routine)
    var exercises: [RoutineExercise]

    var sortedExercises: [RoutineExercise] {
        exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }
    }

    init(
        id: UUID = UUID(), name: String, notes: String = "", createdAt: Date = Date(),
        lastUsed: Date? = nil, scheduledDays: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.createdAt = createdAt
        self.lastUsed = lastUsed
        self.scheduledDays = scheduledDays
        self.exercises = []
    }
}
