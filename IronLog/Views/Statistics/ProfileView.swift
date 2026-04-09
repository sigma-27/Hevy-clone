import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query(sort: \Workout.startTime, order: .reverse) private var workouts: [Workout]
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var bodyWeights: [BodyWeightEntry]
    @Query private var settings: [UserSettings]

    private var completedWorkouts: [Workout] { workouts.filter { !$0.isInProgress } }
    private var useKg: Bool { settings.first?.useKilograms ?? true }

    var body: some View {
        NavigationStack {
            List {
                // Summary stats
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        statCell("\(completedWorkouts.count)", label: "Workouts")
                        statCell(totalVolumeLabel, label: "Total Vol.")
                        statCell(streakLabel, label: "Streak")
                    }
                    .padding(.vertical, 8)
                }

                // Calendar heatmap
                Section("This Month") {
                    CalendarHeatmapView(workouts: completedWorkouts)
                        .padding(.vertical, 4)
                }

                // Stats navigation
                Section("Statistics") {
                    NavigationLink(destination: BodyWeightView()) {
                        Label("Body Weight", systemImage: "scalemass.fill")
                    }
                    NavigationLink(destination: PRListView()) {
                        Label("Personal Records", systemImage: "trophy.fill")
                    }
                    NavigationLink(destination: ProgressPhotosView()) {
                        Label("Progress Photos", systemImage: "photo.stack.fill")
                    }
                }

                // Settings link
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    NavigationLink(destination: PlateCalculatorView()) {
                        Label("Plate Calculator", systemImage: "scalemass")
                    }
                    NavigationLink(destination: BackupRestoreView()) {
                        Label("Backup & Restore", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }

    private var totalVolumeLabel: String {
        let total = completedWorkouts.reduce(0.0) { $0 + $1.totalVolumeKg }
        let display = useKg ? total : total * 2.20462
        if display >= 1_000_000 { return String(format: "%.1fM", display / 1_000_000) }
        if display >= 1_000 { return String(format: "%.0fk", display / 1_000) }
        return String(format: "%.0f", display)
    }

    private var streakLabel: String {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let workoutDays = Set(completedWorkouts.map { calendar.startOfDay(for: $0.startTime) })
        while workoutDays.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
        }
        return "\(streak)d"
    }

    private func statCell(_ value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}
