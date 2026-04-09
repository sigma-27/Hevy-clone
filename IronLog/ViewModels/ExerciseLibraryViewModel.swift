import SwiftUI

@Observable
class ExerciseLibraryViewModel {
    var searchText = ""
    var selectedMuscle: String?
    var selectedEquipment: String?
    var selectedCategory: String?
    var showCustomOnly = false

    var hasActiveFilters: Bool {
        selectedMuscle != nil || selectedEquipment != nil || selectedCategory != nil || showCustomOnly
    }

    func clearFilters() {
        selectedMuscle = nil
        selectedEquipment = nil
        selectedCategory = nil
        showCustomOnly = false
    }

    static let allMuscles = [
        "chest", "back", "lats", "shoulders", "front_delt", "rear_delt",
        "biceps", "triceps", "forearms", "quadriceps", "hamstrings",
        "glutes", "calves", "abs", "obliques", "lower_back", "traps"
    ]

    static let allEquipment = [
        "barbell", "dumbbell", "cable", "machine", "bodyweight",
        "bands", "kettlebell", "other"
    ]

    static let allCategories = ["Strength", "Cardio", "Stretching", "Olympic", "Plyometrics"]
}
