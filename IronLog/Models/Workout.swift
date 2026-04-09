import SwiftData
import Foundation

@Model
final class Workout {
    @Attribute(.unique) var id: UUID
    var title: String
    var startTime: Date
    var endTime: Date?
    var notes: String
    var isInProgress: Bool
    @Relationship(deleteRule: .cascade, inverse: \WorkoutExercise.workout)
    var exercises: [WorkoutExercise]

    var duration: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }

    var totalVolumeKg: Double {
        exercises.flatMap { $0.sets }
            .compactMap { set -> Double? in
                guard set.isCompleted, let w = set.weightKg, let r = set.reps else { return nil }
                return w * Double(r)
            }
            .reduce(0, +)
    }

    var completedSetsCount: Int {
        exercises.flatMap { $0.sets }.filter { $0.isCompleted }.count
    }

    init(
        id: UUID = UUID(), title: String = "Workout", startTime: Date = Date(),
        endTime: Date? = nil, notes: String = "", isInProgress: Bool = true
    ) {
        self.id = id
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.isInProgress = isInProgress
        self.exercises = []
    }
}
