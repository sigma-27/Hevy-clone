import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Query private var settings: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var showingCalendar = false
    @State private var selectedDayWorkouts: [Workout] = []
    @State private var showingDaySheet = false

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
                } else if showingCalendar {
                    ScrollView {
                        CalendarHeatmapView(workouts: completedWorkouts) { date in
                            let cal = Calendar.current
                            selectedDayWorkouts = completedWorkouts.filter {
                                cal.isDate($0.startTime, inSameDayAs: date)
                            }
                            if !selectedDayWorkouts.isEmpty { showingDaySheet = true }
                        }
                        .padding(.top)
                    }
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showingCalendar.toggle() }
                    } label: {
                        Image(systemName: showingCalendar ? "list.bullet" : "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingDaySheet) {
                DayWorkoutsSheet(workouts: selectedDayWorkouts, useKg: useKg)
                    .presentationDetents([.medium, .large])
            }
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

// MARK: - Day detail sheet (from calendar tap)

private struct DayWorkoutsSheet: View {
    var workouts: [Workout]
    var useKg: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(workout.title).font(.subheadline).fontWeight(.semibold)
                            HStack(spacing: 10) {
                                Text(workout.startTime.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundStyle(.secondary)
                                let vol = useKg ? workout.totalVolumeKg : workout.totalVolumeKg * 2.20462
                                Text(String(format: "%.0f %@", vol, useKg ? "kg" : "lbs"))
                                    .font(.caption).foregroundStyle(.secondary)
                                Text("\(workout.completedSetsCount) sets")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle(workouts.first.map {
                $0.startTime.formatted(date: .complete, time: .omitted)
            } ?? "Workouts")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
