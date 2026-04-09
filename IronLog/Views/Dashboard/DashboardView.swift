import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Query private var routines: [Routine]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Quick start card
                    quickStartCard
                    // Recent workouts
                    if !workouts.filter({ !$0.isInProgress }).isEmpty {
                        recentWorkoutsSection
                    } else {
                        EmptyStateView(
                            title: "No workouts yet",
                            message: "Start your first workout to see it here",
                            systemImage: "flame"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
        }
    }

    private var quickStartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ready to train?")
                .font(.headline)
            Button {
                let workout = Workout(title: "Workout \(Date().formatted(date: .abbreviated, time: .omitted))")
                modelContext.insert(workout)
                appState.startWorkout(workout)
            } label: {
                Label("Start Empty Workout", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Workouts")
                .font(.headline)
            ForEach(workouts.filter { !$0.isInProgress }.prefix(5)) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutRowView(workout: workout)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct WorkoutRowView: View {
    var workout: Workout
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.title).font(.subheadline).fontWeight(.semibold)
                Text(workout.startTime.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(durationString).font(.caption).foregroundStyle(.secondary)
                Text("\(workout.completedSetsCount) sets").font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var durationString: String {
        let mins = Int(workout.duration / 60)
        return mins < 60 ? "\(mins)m" : "\(mins / 60)h \(mins % 60)m"
    }
}
