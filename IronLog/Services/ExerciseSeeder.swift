import SwiftData
import Foundation

struct ExerciseSeeder {
    private static let seededKey = "IronLog.exercisesSeeded.v1"

    static func seedIfNeeded(modelContainer: ModelContainer) async {
        guard !UserDefaults.standard.bool(forKey: seededKey) else { return }
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seeds = try? JSONDecoder().decode([ExerciseSeed].self, from: data) else { return }

        let context = ModelContext(modelContainer)
        for seed in seeds {
            let ex = Exercise(
                name: seed.name, category: seed.category,
                primaryMuscles: seed.primaryMuscles,
                secondaryMuscles: seed.secondaryMuscles,
                equipment: seed.equipment,
                instructions: seed.instructions
            )
            context.insert(ex)
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: seededKey)
    }

    private struct ExerciseSeed: Decodable {
        let name: String
        let category: String
        let primaryMuscles: [String]
        let secondaryMuscles: [String]
        let equipment: String
        let instructions: String
    }
}
