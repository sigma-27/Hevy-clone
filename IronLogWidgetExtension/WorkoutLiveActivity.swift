import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Widget entry point

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock screen / StandBy / notification banner
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color(red: 0.08, green: 0.08, blue: 0.10))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // ── Expanded (long-press on Dynamic Island) ──────────────────
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(context.attributes.workoutTitle)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            // Self-updating elapsed timer — no per-second Activity updates needed
                            Text(
                                timerInterval: context.attributes.workoutStartDate...Date.distantFuture,
                                countsDown: false
                            )
                            .monospacedDigit()
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 4)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("Set \(context.state.currentSetNumber)/\(context.state.totalSets)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("\(context.state.completedSetsCount) done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 4)
                }

                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.currentExerciseName)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.top, 2)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // Rest timer — shown only while rest is running
                        if context.state.isRestTimerRunning,
                           let startDate = context.state.restTimerStartDate,
                           let endDate = context.state.restTimerEndDate {
                            restTimerRow(startDate: startDate, endDate: endDate, compact: true)
                        }

                        // Action buttons
                        HStack(spacing: 8) {
                            // Complete next set
                            Link(destination: URL(string: "ironlog://complete-set")!) {
                                Label("Complete Set", systemImage: "checkmark.circle.fill")
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.green.opacity(0.22))
                                    .foregroundStyle(.green)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            // Skip rest (only while rest timer is running)
                            if context.state.isRestTimerRunning {
                                Link(destination: URL(string: "ironlog://skip-rest")!) {
                                    Label("Skip", systemImage: "forward.fill")
                                        .font(.caption.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color.orange.opacity(0.18))
                                        .foregroundStyle(.orange)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }

            } compactLeading: {
                // ── Compact leading: flame + elapsed clock ───────────────────
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text(
                        timerInterval: context.attributes.workoutStartDate...Date.distantFuture,
                        countsDown: false
                    )
                    .monospacedDigit()
                    .font(.caption2.weight(.semibold))
                    .frame(width: 38, alignment: .leading)
                    .foregroundStyle(.white)
                }

            } compactTrailing: {
                // ── Compact trailing: exercise name ──────────────────────────
                Text(context.state.currentExerciseName)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: 84, alignment: .trailing)

            } minimal: {
                // ── Minimal (tiny circle) ────────────────────────────────────
                Image(systemName: "flame.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
            .widgetURL(URL(string: "ironlog://workout"))
            .keylineTint(.orange)
        }
    }

    // MARK: - Shared rest timer row

    @ViewBuilder
    private func restTimerRow(startDate: Date, endDate: Date, compact: Bool) -> some View {
        VStack(spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(compact ? .caption2 : .caption)
                    .foregroundStyle(.orange)
                Text("Rest")
                    .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Spacer()
                Text(timerInterval: Date.now...endDate, countsDown: true)
                    .monospacedDigit()
                    .font(compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                    .foregroundStyle(.orange)
            }
            ProgressView(timerInterval: startDate...endDate, countsDown: true) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .progressViewStyle(.linear)
            .tint(.orange)
        }
    }
}

// MARK: - Lock screen / StandBy / banner view

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                Image(systemName: "flame.fill").foregroundStyle(.orange)
                Text(context.attributes.workoutTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer()
                Text(
                    timerInterval: context.attributes.workoutStartDate...Date.distantFuture,
                    countsDown: false
                )
                .monospacedDigit()
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            }

            Divider().overlay(Color.white.opacity(0.15))

            // Exercise + set info
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(context.state.currentExerciseName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(
                        "Set \(context.state.currentSetNumber) of \(context.state.totalSets)" +
                        " · \(context.state.completedSetsCount) completed"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Rest timer
            if context.state.isRestTimerRunning,
               let startDate = context.state.restTimerStartDate,
               let endDate = context.state.restTimerEndDate {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "timer").font(.caption).foregroundStyle(.orange)
                        Text("Rest").font(.caption.weight(.semibold)).foregroundStyle(.orange)
                        Spacer()
                        Text(timerInterval: Date.now...endDate, countsDown: true)
                            .monospacedDigit()
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                    ProgressView(timerInterval: startDate...endDate, countsDown: true) {
                        EmptyView()
                    } currentValueLabel: { EmptyView() }
                    .progressViewStyle(.linear)
                    .tint(.orange)
                }
            }

            // Action buttons
            HStack(spacing: 10) {
                Link(destination: URL(string: "ironlog://complete-set")!) {
                    Label("Complete Set", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.green.opacity(0.22))
                        .foregroundStyle(.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                if context.state.isRestTimerRunning {
                    Link(destination: URL(string: "ironlog://skip-rest")!) {
                        Label("Skip Rest", systemImage: "forward.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.orange.opacity(0.18))
                            .foregroundStyle(.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(16)
    }
}
