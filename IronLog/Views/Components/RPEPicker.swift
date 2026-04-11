import SwiftUI

struct RPEPicker: View {
    @Binding var rpe: Double?

    var body: some View {
        Menu {
            Button("Clear RPE") { rpe = nil }
            ForEach(stride(from: 10.0, through: 1.0, by: -0.5).map { $0 }, id: \.self) { value in
                Button("RPE \(value.formatted(.number.precision(.fractionLength(value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1))))") {
                    rpe = value
                }
            }
        } label: {
            if let r = rpe {
                Text("@\(r.formatted(.number.precision(.fractionLength(r.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 1))))")
                    .font(.caption).foregroundStyle(.accentColor)
            } else {
                Image(systemName: "gauge").font(.caption).foregroundStyle(.tertiary)
            }
        }
    }
}
