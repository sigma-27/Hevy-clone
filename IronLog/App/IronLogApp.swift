import SwiftUI
import SwiftData

@main
struct IronLogApp: App {
    @State private var appState = AppState()
    @AppStorage("appTheme") private var appTheme = "system"
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

    private var preferredColorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(preferredColorScheme)
                .task {
                    await ExerciseSeeder.seedIfNeeded(modelContainer: modelContainer)
                    await UserSettingsManager.ensureExists(modelContainer: modelContainer)
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Deep link handler
    //
    // URL scheme:  ironlog://<action>
    //   ironlog://workout        → bring active workout to front
    //   ironlog://complete-set   → complete next incomplete set, start rest timer
    //   ironlog://skip-rest      → stop rest timer immediately
    //
    // These URLs are embedded in the Live Activity / Dynamic Island buttons.

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "ironlog" else { return }

        // Always surface the active workout sheet first
        if appState.activeWorkout != nil {
            appState.showingActiveWorkout = true
        }

        switch url.host {
        case "complete-set":
            // Delegate to ActiveWorkoutView via the stored closure
            appState.completeNextSetAction?()

        case "skip-rest":
            appState.stopRestTimer()

        default:
            break  // "workout" — just surfacing the sheet is enough
        }
    }
}
