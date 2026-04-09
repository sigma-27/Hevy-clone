import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(Tab.dashboard)
            WorkoutTabView()
                .tabItem { Label("Workout", systemImage: "flame.fill") }
                .tag(Tab.workout)
            ExerciseListView()
                .tabItem { Label("Exercises", systemImage: "books.vertical.fill") }
                .tag(Tab.exercises)
            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "chart.bar.fill") }
                .tag(Tab.profile)
        }
        .sheet(isPresented: $appState.showingActiveWorkout) {
            if let workout = appState.activeWorkout {
                ActiveWorkoutView(workout: workout)
                    .interactiveDismissDisabled()
            }
        }
    }
}
