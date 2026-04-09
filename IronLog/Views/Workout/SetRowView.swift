import SwiftUI
import SwiftData

struct SetRowView: View {
    @Bindable var set: WorkoutSet
    var setIndex: Int = 0
    var useKg: Bool = true
    var onCompleted: () -> Void = {}

    @State private var weightString = ""
    @State private var repsString = ""

    var body: some View {
        HStack(spacing: 0) {
            // Set number badge
            setTypeBadge.frame(width: 44)

            // Previous
            previousText.frame(maxWidth: .infinity)

            // Weight input
            TextField("0", text: $weightString)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.center)
                .frame(width: 70)
                .onChange(of: weightString) { _, new in
                    if let v = Double(new) {
                        set.weightKg = useKg ? v : v * 0.453592
                    } else if new.isEmpty {
                        set.weightKg = nil
                    }
                }

            // Reps input
            TextField("0", text: $repsString)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .frame(width: 60)
                .onChange(of: repsString) { _, new in
                    set.reps = Int(new)
                }

            // Complete checkbox
            Button { toggleComplete() } label: {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .frame(width: 44)
        }
        .padding(.vertical, 6).padding(.horizontal, 8)
        .background(set.isCompleted ? Color.green.opacity(0.08) : Color.clear)
        .animation(.easeInOut(duration: 0.15), value: set.isCompleted)
        .onAppear { syncDisplayValues() }
    }

    private var setTypeBadge: some View {
        Group {
            switch set.setType {
            case "warmup":
                Text("W").font(.caption).bold().foregroundStyle(.orange)
            case "dropset":
                Text("D").font(.caption).bold().foregroundStyle(.purple)
            case "failure":
                Text("F").font(.caption).bold().foregroundStyle(.red)
            default:
                Text("\(set.setNumber)").font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }

    private var previousText: some View {
        Text(previousLabel)
            .font(.caption)
            .foregroundStyle(.tertiary)
            .lineLimit(1)
    }

    private var previousLabel: String { "—" }

    private func toggleComplete() {
        set.isCompleted.toggle()
        if set.isCompleted { onCompleted() }
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
