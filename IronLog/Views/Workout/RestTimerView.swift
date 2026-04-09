import SwiftUI

struct RestTimerView: View {
    var remaining: TimeInterval
    var total: TimeInterval
    var onSkip: () -> Void = {}
    var onAddTime: ((TimeInterval) -> Void)? = nil

    private var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, 1 - remaining / total))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Circular progress
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: progress)
                Text(timerLabel)
                    .font(.caption.monospacedDigit()).fontWeight(.semibold)
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Timer").font(.subheadline).fontWeight(.semibold)
                Text("Next set in \(timerLabel)").font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            // Adjust time buttons
            if let addTime = onAddTime {
                HStack(spacing: 4) {
                    Button { addTime(-15) } label: {
                        Image(systemName: "minus.circle")
                            .font(.title3).foregroundStyle(.secondary)
                    }
                    Button { addTime(30) } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3).foregroundStyle(.secondary)
                    }
                }
            }

            Button("Skip", action: onSkip)
                .font(.subheadline).foregroundStyle(.accentColor)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var timerLabel: String {
        let t = max(0, Int(remaining))
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
