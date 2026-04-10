import ActivityKit
import Foundation

/// Shared between the main IronLog target and IronLogWidgetExtension.
/// Defines static attributes and dynamic content state for the active-workout Live Activity.
struct WorkoutActivityAttributes: ActivityAttributes {

    // MARK: - Dynamic state (changes throughout workout)

    struct ContentState: Codable, Hashable {
        /// Snapshot — actual elapsed display uses workoutStartDate + Text(timerInterval:)
        var elapsedSeconds: Int
        var currentExerciseName: String
        var currentSetNumber: Int
        var totalSets: Int
        var completedSetsCount: Int

        // Rest timer — nil when not running; used by ProgressView(timerInterval:) + Text(timerInterval:)
        var isRestTimerRunning: Bool
        var restTimerStartDate: Date?   // start of rest period (for progress bar)
        var restTimerEndDate: Date?     // end of rest period (for countdown + progress bar)
        var restTimerTotalSeconds: Int
    }

    // MARK: - Static attributes (set once at activity start)

    var workoutTitle: String
    /// Used by Text(timerInterval:) for a self-updating elapsed clock — no per-second pushes needed.
    var workoutStartDate: Date
}
