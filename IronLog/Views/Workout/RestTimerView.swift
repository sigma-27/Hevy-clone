import SwiftUI

struct RestTimerView: View {
    var remaining: TimeInterval
    var total: TimeInterval
    var onSkip: () -> Void = {}

    private var progress: Double {
        guard total > 0 else { return 0 }
        return max(0, min(1, 1 - remaining / total))
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                Text(timerLabel)
                    .font(.subheadline.monospacedDigit()).fontWeight(.semibold)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Timer").font(.subheadline).fontWeight(.semibold)
                Text("Next set in \(timerLabel)").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Skip", action: onSkip)
                .font(.subheadline).foregroundStyle(.accentColor)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var timerLabel: String {
        let t = Int(remaining)
        return String(format: "%d:%02d", t / 60, t % 60)
    }
}
