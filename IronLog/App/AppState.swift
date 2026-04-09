import SwiftUI
import SwiftData
import Combine
import UserNotifications

@Observable
class AppState {
    var selectedTab: Tab = .dashboard
    var activeWorkout: Workout?
    var showingActiveWorkout = false
    var restTimerRemaining: TimeInterval = 0
    var isRestTimerRunning = false
    var restTimerTotal: TimeInterval = 90

    private var timerCancellable: AnyCancellable?
    private var timerStartDate: Date?

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
                } else {
                    self.restTimerRemaining = remaining
                }
            }
    }

    func stopRestTimer() {
        timerCancellable?.cancel()
        isRestTimerRunning = false
        restTimerRemaining = 0
        timerStartDate = nil
        RestTimerService.cancelNotification()
    }

    func addRestTime(_ seconds: TimeInterval) {
        guard isRestTimerRunning, let start = timerStartDate else { return }
        // Shift the start date back to effectively add time
        timerStartDate = start.addingTimeInterval(-seconds)
        restTimerTotal += seconds
    }
}

enum Tab: Int, Hashable {
    case dashboard, workout, exercises, history, profile
}
