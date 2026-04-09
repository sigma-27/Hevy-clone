import SwiftUI

struct RPEPicker: View {
    @Binding var rpe: Double?

    var body: some View {
        Menu {
            Button("Clear RPE") { rpe = nil }
            ForEach([6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0], id: \.self) { value in
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
