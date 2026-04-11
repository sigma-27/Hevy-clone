import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Query private var settings: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    private var useKg: Bool { settings.first?.useKilograms ?? true }

    private var completedWorkouts: [Workout] { workouts.filter { !$0.isInProgress } }

    private var groupedByMonth: [(String, [Workout])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: completedWorkouts) { formatter.string(from: $0.startTime) }
        return grouped.sorted { a, b in
            guard let dateA = formatter.date(from: a.key), let dateB = formatter.date(from: b.key) else { return false }
            return dateA > dateB
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completedWorkouts.isEmpty {
                    EmptyStateView(title: "No Workouts Yet", message: "Your completed workouts will appear here.", systemImage: "clock.arrow.circlepath")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupedByMonth, id: \.0) { month, monthWorkouts in
                            Section(month) {
                                ForEach(monthWorkouts) { workout in
                                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                        historyRow(workout)
                                    }
                                }
                                .onDelete { offsets in
                                    deleteWorkouts(from: monthWorkouts, at: offsets)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }

    private func historyRow(_ workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(workout.title).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text(durationLabel(workout)).font(.caption).foregroundStyle(.secondary)
            }
            Text(workout.startTime.formatted(date: .complete, time: .shortened))
                .font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Label("\(workout.exercises.count) exercises", systemImage: "list.bullet")
                Label("\(workout.completedSetsCount) sets", systemImage: "number")
                let vol = useKg ? workout.totalVolumeKg : workout.totalVolumeKg * 2.20462
                Label(String(format: "%.0f %@", vol, useKg ? "kg" : "lbs"), systemImage: "scalemass")
            }
            .font(.caption2).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private func durationLabel(_ workout: Workout) -> String {
        let m = Int(workout.duration / 60)
        return m < 60 ? "\(m)m" : "\(m/60)h \(m%60)m"
    }

    private func deleteWorkouts(from list: [Workout], at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(list[index])
        }
        try? modelContext.save()
    }
}
