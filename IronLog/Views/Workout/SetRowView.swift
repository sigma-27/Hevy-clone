import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    var setIndex: Int = 0
    var useKg: Bool = true
    var previousWeightKg: Double? = nil
    var previousReps: Int? = nil
    var showRPE: Bool = true
    var onCompleted: () -> Void = {}

    @State private var weightString = ""
    @State private var repsString = ""
    @FocusState private var focusedField: Field?

    private enum Field { case weight, reps }

    var body: some View {
        HStack(spacing: 0) {
            // Set type badge
            setTypeBadge.frame(width: 44)

            // Previous performance
            previousText.frame(maxWidth: .infinity)

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

            // RPE (optional)
            if showRPE {
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
    }

    // MARK: - Sub-views

    private var setTypeBadge: some View {
        Menu {
            Button("Normal") { set.setType = "normal" }
            Button("Warm-up") { set.setType = "warmup" }
            Button("Drop Set") { set.setType = "dropset" }
            Button("To Failure") { set.setType = "failure" }
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
    }

    private var previousText: some View {
        Text(previousLabel)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
    }

    private var previousLabel: String {
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

    private func syncDisplayValues() {
        if let w = set.weightKg {
            let display = useKg ? w : w * 2.20462
            weightString = display.truncatingRemainder(dividingBy: 1) == 0
                ? "\(Int(display))" : String(format: "%.1f", display)
        }
        if let r = set.reps { repsString = "\(r)" }
    }
}
