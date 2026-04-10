import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    var setIndex: Int = 0
    var useKg: Bool = true
    var previousWeightKg: Double? = nil
    var previousReps: Int? = nil
    var previousDurationSeconds: Int? = nil
    var previousDistanceMeters: Double? = nil
    var showRPE: Bool = true
    var isCardio: Bool = false
    var onCompleted: () -> Void = {}
    var onDelete: () -> Void = {}

    @State private var weightString = ""
    @State private var repsString = ""
    @State private var durationString = ""   // "MM:SS" for cardio
    @State private var distanceString = ""   // km or miles for cardio
    @FocusState private var focusedField: Field?

    private enum Field { case weight, reps, duration, distance }

    var body: some View {
        HStack(spacing: 0) {
            // Set type badge / number
            setTypeBadge.frame(width: 44)

            // Previous performance
            previousText.frame(maxWidth: .infinity)

            if isCardio {
                // Duration input (MM:SS)
                TextField("0:00", text: $durationString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .focused($focusedField, equals: .duration)
                    .onChange(of: durationString) { _, new in
                        set.durationSeconds = parseDuration(new)
                    }

                // Distance input
                TextField("0.0", text: $distanceString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 56)
                    .focused($focusedField, equals: .distance)
                    .onChange(of: distanceString) { _, new in
                        if let v = Double(new.replacingOccurrences(of: ",", with: ".")) {
                            // store internally as meters
                            set.distanceMeters = useKg ? v * 1000 : v * 1609.344
                        } else if new.isEmpty {
                            set.distanceMeters = nil
                        }
                    }
            } else {
                // Weight input
                TextField("0", text: $weightString)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 70)
                    .focused($focusedField, equals: .weight)
                    .onChange(of: weightString) { _, new in
                        if let v = Double(new.replacingOccurrences(of: ",", with: ".")) {
                            set.weightKg = useKg ? v : v * 0.453592
                        } else if new.isEmpty {
                            set.weightKg = nil
                        }
                    }

                // Reps input
                TextField("0", text: $repsString)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 56)
                    .focused($focusedField, equals: .reps)
                    .onChange(of: repsString) { _, new in
                        set.reps = Int(new)
                    }
            }

            // RPE (strength only)
            if showRPE && !isCardio {
                RPEPicker(rpe: $set.rpe)
                    .frame(width: 36)
            }

            // Complete checkbox
            Button { toggleComplete() } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .frame(width: 44)
        }
        .padding(.vertical, 8).padding(.horizontal, 8)
        .background(set.isCompleted ? Color.green.opacity(0.08) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: set.isCompleted)
        .onAppear { syncDisplayValues() }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
                    .fontWeight(.semibold)
            }
        }
        // ── Long-press context menu (Hevy-style) ──────────────────────────
        .contextMenu {
            // Set type options
            Button {
                set.setType = "warmup"
            } label: {
                Label("Warm Up Set", systemImage: "thermometer.medium")
            }

            Button {
                set.setType = "normal"
            } label: {
                Label("Normal Set", systemImage: "checkmark")
            }

            Button {
                set.setType = "failure"
            } label: {
                Label("Failure Set", systemImage: "xmark.circle")
            }

            Button {
                set.setType = "dropset"
            } label: {
                Label("Drop Set", systemImage: "arrow.down.circle")
            }

            Divider()

            // Remove
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Remove Set", systemImage: "trash")
            }
        }
    }

    // MARK: - Sub-views

    private var setTypeBadge: some View {
        // Tapping the badge still cycles type (quick alternative to long-press)
        Button {
            cycleSetType()
        } label: {
            switch set.setType {
            case "warmup":
                Text("W").font(.caption2).bold().foregroundStyle(.orange)
                    .frame(width: 26, height: 26)
                    .background(Color.orange.opacity(0.15)).clipShape(Circle())
            case "dropset":
                Text("D").font(.caption2).bold().foregroundStyle(.purple)
                    .frame(width: 26, height: 26)
                    .background(Color.purple.opacity(0.15)).clipShape(Circle())
            case "failure":
                Text("F").font(.caption2).bold().foregroundStyle(.red)
                    .frame(width: 26, height: 26)
                    .background(Color.red.opacity(0.15)).clipShape(Circle())
            default:
                Text("\(set.setNumber)").font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var previousText: some View {
        Text(previousLabel)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
    }

    private var previousLabel: String {
        if isCardio {
            if let d = previousDurationSeconds {
                let dist = previousDistanceMeters.map { useKg ? $0 / 1000 : $0 / 1609.344 }
                let dStr = formatDuration(d)
                if let dist { return "\(dStr) · \(String(format: "%.2f", dist))" }
                return dStr
            }
            return "—"
        }
        guard let w = previousWeightKg, let r = previousReps else { return "—" }
        let display = useKg ? w : w * 2.20462
        let wStr = display.truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(display))" : String(format: "%.1f", display)
        return "\(wStr) × \(r)"
    }

    // MARK: - Actions

    private func toggleComplete() {
        set.isCompleted.toggle()
        if set.isCompleted {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onCompleted()
        }
        syncDisplayValues()
    }

    private func cycleSetType() {
        let order = ["normal", "warmup", "dropset", "failure"]
        let idx = order.firstIndex(of: set.setType) ?? 0
        set.setType = order[(idx + 1) % order.count]
    }

    private func syncDisplayValues() {
        if isCardio {
            if let d = set.durationSeconds { durationString = formatDuration(d) }
            if let dist = set.distanceMeters {
                let display = useKg ? dist / 1000 : dist / 1609.344
                distanceString = String(format: "%.2f", display)
            }
        } else {
            if let w = set.weightKg {
                let display = useKg ? w : w * 2.20462
                weightString = display.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(display))" : String(format: "%.1f", display)
            }
            if let r = set.reps { repsString = "\(r)" }
        }
    }

    // MARK: - Duration helpers

    /// Parse "M:SS" or plain digits (treated as total seconds) → seconds
    private func parseDuration(_ raw: String) -> Int? {
        let parts = raw.split(separator: ":").map { Int($0) }
        if parts.count == 2, let m = parts[0], let s = parts[1] {
            return m * 60 + s
        }
        if let total = Int(raw) { return total }
        return nil
    }

    private func formatDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
