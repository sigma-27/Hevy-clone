import SwiftUI
import SwiftData
import Combine
import UserNotifications
import ActivityKit

@Observable
class AppState {
    var selectedTab: Tab = .dashboard
    var activeWorkout: Workout?
    var showingActiveWorkout = false
    var restTimerRemaining: TimeInterval = 0
    var isRestTimerRunning = false
    var restTimerTotal: TimeInterval = 90

    /// Set by ActiveWorkoutView so URL-triggered "complete set" can reach the model layer.
    var completeNextSetAction: (() -> Void)?

    private var timerCancellable: AnyCancellable?
    private var timerStartDate: Date?

    // MARK: - Workout lifecycle

    func startWorkout(_ workout: Workout) {
        activeWorkout = workout
        showingActiveWorkout = true
    }

    func endWorkout() {
        endLiveActivity()
        activeWorkout = nil
        showingActiveWorkout = false
        completeNextSetAction = nil
        stopRestTimer()
    }

    // MARK: - Rest timer

    func startRestTimer(seconds: TimeInterval) {
        restTimerTotal = seconds
        restTimerRemaining = seconds
        isRestTimerRunning = true
        timerStartDate = Date()
        RestTimerService.scheduleNotification(seconds: seconds)

        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.timerStartDate else { return }
                let elapsed = Date().timeIntervalSince(start)
                let remaining = self.restTimerTotal - elapsed
                if remaining <= 0 {
                    self.restTimerRemaining = 0
                    self.isRestTimerRunning = false
                    self.timerCancellable?.cancel()
                    if let workout = self.activeWorkout { self.updateLiveActivity(workout: workout) }
                } else {
                    self.restTimerRemaining = remaining
                }
            }

        if let workout = activeWorkout { updateLiveActivity(workout: workout) }
    }

    func stopRestTimer() {
        timerCancellable?.cancel()
        isRestTimerRunning = false
        restTimerRemaining = 0
        timerStartDate = nil
        RestTimerService.cancelNotification()
        if let workout = activeWorkout { updateLiveActivity(workout: workout) }
    }

    func addRestTime(_ seconds: TimeInterval) {
        guard isRestTimerRunning, let start = timerStartDate else { return }
        timerStartDate = start.addingTimeInterval(-seconds)
        restTimerTotal += seconds
        if let workout = activeWorkout { updateLiveActivity(workout: workout) }
    }

    // MARK: - Live Activity

    func startLiveActivity(workout: Workout) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = WorkoutActivityAttributes(
            workoutTitle: workout.title,
            workoutStartDate: workout.startTime
        )
        do {
            _ = try Activity<WorkoutActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: liveActivityState(for: workout), staleDate: nil),
                pushType: nil
            )
        } catch {
            // Live Activities unavailable on this device / simulator — silent fail
            print("Live Activity start failed: \(error.localizedDescription)")
        }
    }

    func updateLiveActivity(workout: Workout) {
        let state = liveActivityState(for: workout)
        Task {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                await activity.update(.init(state: state, staleDate: nil))
            }
        }
    }

    func endLiveActivity() {
        Task {
            for activity in Activity<WorkoutActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Live Activity state snapshot

    private func liveActivityState(for workout: Workout) -> WorkoutActivityAttributes.ContentState {
        let sorted = workout.exercises.sorted { $0.exerciseOrder < $1.exerciseOrder }

        // Current exercise = first that still has an incomplete set
        let currentEx = sorted.first { $0.sortedSets.contains { !$0.isCompleted } } ?? sorted.last
        let completedInEx = currentEx?.sortedSets.filter(\.isCompleted).count ?? 0
        let totalInEx = currentEx?.sets.count ?? 0

        // Rest timer dates computed from current remaining / total
        let restStart: Date? = isRestTimerRunning
            ? Date().addingTimeInterval(-(restTimerTotal - restTimerRemaining))
            : nil
        let restEnd: Date? = isRestTimerRunning
            ? Date().addingTimeInterval(restTimerRemaining)
            : nil

        return WorkoutActivityAttributes.ContentState(
            elapsedSeconds: Int(Date().timeIntervalSince(workout.startTime)),
            currentExerciseName: currentEx?.exercise?.name ?? workout.title,
            currentSetNumber: min(completedInEx + 1, max(totalInEx, 1)),
            totalSets: max(totalInEx, 1),
            completedSetsCount: workout.completedSetsCount,
            isRestTimerRunning: isRestTimerRunning,
            restTimerStartDate: restStart,
            restTimerEndDate: restEnd,
            restTimerTotalSeconds: Int(restTimerTotal)
        )
    }
}

enum Tab: Int, Hashable {
    case dashboard, workout, exercises, history, profile
}
