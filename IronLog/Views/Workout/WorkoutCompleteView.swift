import SwiftUI

struct WorkoutCompleteView: View {
    var workout: Workout
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64)).foregroundStyle(.green)
            Text("Workout Complete!").font(.title).fontWeight(.bold)
            statsGrid
            Button("Done", action: onDismiss)
                .frame(maxWidth: .infinity).padding()
                .background(Color.accentColor).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
        }
        .padding()
    }

    private var statsGrid: some View {
        let duration = workout.duration
        let mins = Int(duration / 60)
        let durationStr = mins < 60 ? "\(mins)m" : "\(mins / 60)h \(mins % 60)m"
        let volume = workout.totalVolumeKg
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCell(value: durationStr, label: "Duration")
            statCell(value: "\(workout.completedSetsCount)", label: "Sets")
            statCell(value: String(format: "%.0f kg", volume), label: "Volume")
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).fontWeight(.bold)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
