import SwiftUI

struct WeightInputField: View {
    @Binding var valueKg: Double?
    var useKg: Bool = true
    var placeholder: String = "0"

    @State private var text = ""

    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.center)
            .onAppear { syncFromModel() }
            .onChange(of: text) { _, new in
                if let v = Double(new) {
                    valueKg = useKg ? v : v * 0.453592
                } else if new.isEmpty {
                    valueKg = nil
                }
            }
            .onChange(of: valueKg) { _, _ in syncFromModel() }
    }

    private func syncFromModel() {
        guard let v = valueKg else { text = ""; return }
        let display = useKg ? v : v * 2.20462
        text = display.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(display))" : String(format: "%.1f", display)
    }
}
