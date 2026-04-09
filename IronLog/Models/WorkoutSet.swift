import SwiftData
import Foundation

@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var weightKg: Double?
    var reps: Int?
    var rpe: Double?
    var durationSeconds: Int?
    var distanceMeters: Double?
    var isCompleted: Bool
    var setType: String   // "normal", "warmup", "dropset", "failure"
    var workoutExercise: WorkoutExercise?

    init(
        id: UUID = UUID(), setNumber: Int, weightKg: Double? = nil, reps: Int? = nil,
        rpe: Double? = nil, durationSeconds: Int? = nil, distanceMeters: Double? = nil,
        isCompleted: Bool = false, setType: String = "normal"
    ) {
        self.id = id
        self.setNumber = setNumber
        self.weightKg = weightKg
        self.reps = reps
        self.rpe = rpe
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.isCompleted = isCompleted
        self.setType = setType
    }
}
