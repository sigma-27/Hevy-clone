import SwiftUI
import SwiftData

@Observable
class AppState {
    var selectedTab: Tab = .dashboard
    var activeWorkout: Workout?
    var showingActiveWorkout = false
    var restTimerRemaining: TimeInterval = 0
    var isRestTimerRunning = false
    var restTimerTotal: TimeInterval = 90

    func startWorkout(_ workout: Workout) {
        activeWorkout = workout
        showingActiveWorkout = true
    }

    func endWorkout() {
        activeWorkout = nil
        showingActiveWorkout = false
        stopRestTimer()
    }

    func startRestTimer(seconds: TimeInterval) {
        restTimerTotal = seconds
        restTimerRemaining = seconds
        isRestTimerRunning = true
    }

    func stopRestTimer() {
        isRestTimerRunning = false
        restTimerRemaining = 0
    }
}

enum Tab: Int, Hashable {
    case dashboard, workout, exercises, history, profile
}
