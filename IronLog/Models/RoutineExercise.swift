import SwiftData
import Foundation

@Model
final class RoutineExercise {
    @Attribute(.unique) var id: UUID
    var exerciseOrder: Int
    var targetSets: Int
    var targetReps: String
    var targetWeightKg: Double?
    var supersetGroup: Int?
    var notes: String
    var autoProgressEnabled: Bool
    var autoProgressWeightKg: Double
    var routine: Routine?
    var exercise: Exercise?

    init(
        id: UUID = UUID(), exerciseOrder: Int, targetSets: Int = 3,
        targetReps: String = "8-12", targetWeightKg: Double? = nil,
        supersetGroup: Int? = nil, notes: String = "",
        autoProgressEnabled: Bool = false, autoProgressWeightKg: Double = 2.5
    ) {
        self.id = id
        self.exerciseOrder = exerciseOrder
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetWeightKg = targetWeightKg
        self.supersetGroup = supersetGroup
        self.notes = notes
        self.autoProgressEnabled = autoProgressEnabled
        self.autoProgressWeightKg = autoProgressWeightKg
    }
}
