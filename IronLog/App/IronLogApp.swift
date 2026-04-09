import SwiftUI
import SwiftData

@main
struct IronLogApp: App {
    @State private var appState = AppState()
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([
                Exercise.self,
                Workout.self,
                WorkoutExercise.self,
                WorkoutSet.self,
                Routine.self,
                RoutineExercise.self,
                BodyWeightEntry.self,
                ProgressPhoto.self,
                UserSettings.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task {
                    await ExerciseSeeder.seedIfNeeded(modelContainer: modelContainer)
                    await UserSettingsManager.ensureExists(modelContainer: modelContainer)
                }
        }
        .modelContainer(modelContainer)
    }
}
