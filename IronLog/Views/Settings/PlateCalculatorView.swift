import SwiftUI
import SwiftData

struct PlateCalculatorView: View {
    @Query private var settingsArr: [UserSettings]
    @State private var targetWeight = ""
    @State private var result: PlateCalculator.Result?

    private var settings: UserSettings? { settingsArr.first }
    private var useKg: Bool { settings?.useKilograms ?? true }

    private var plates: [Double] {
        useKg ? (settings?.availablePlatesKg ?? [1.25, 2.5, 5, 10, 15, 20, 25])
               : (settings?.availablePlatesLbs ?? [2.5, 5, 10, 25, 35, 45])
    }
    private var barWeight: Double {
        useKg ? (settings?.barWeightKg ?? 20) : (settings?.barWeightLbs ?? 45)
    }

    var body: some View {
        List {
            Section("Target Weight (\(WeightConverter.unitLabel(useKg)))") {
                HStack {
                    TextField("e.g. 100", text: $targetWeight).keyboardType(.decimalPad)
                    Button("Calculate") {
                        guard let target = Double(targetWeight) else { return }
                        let targetKg = useKg ? target : target * 0.453592
                        let barKg = useKg ? barWeight : barWeight * 0.453592
                        let platesKg = useKg ? plates : plates.map { $0 * 0.453592 }
                        result = PlateCalculator.calculate(targetKg: targetKg, barKg: barKg, availablePlates: platesKg)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(Double(targetWeight) == nil)
                }
            }

            if let r = result {
                Section("Plates Per Side") {
                    if r.platesPerSide.isEmpty {
                        Text("Bar only (\(barWeight.formatted()) \(WeightConverter.unitLabel(useKg)))")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(r.platesPerSide, id: \.weight) { plate in
                            HStack {
                                plateCircle(plate.weight)
                                Text("× \(plate.count)").font(.headline)
                                Spacer()
                                Text("\(plate.weight.formatted()) \(WeightConverter.unitLabel(useKg))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Total Weight") {
                    HStack {
                        Text("Actual").fontWeight(.semibold)
                        Spacer()
                        let display = useKg ? r.actualWeight : r.actualWeight * 2.20462
                        Text("\(display.formatted(.number.precision(.fractionLength(1)))) \(WeightConverter.unitLabel(useKg))")
                            .fontWeight(.bold).foregroundStyle(.accentColor)
                    }
                    HStack {
                        Text("Bar").foregroundStyle(.secondary)
                        Spacer()
                        Text("\(barWeight.formatted()) \(WeightConverter.unitLabel(useKg))").foregroundStyle(.secondary)
                    }
                }
            }

            Section("Bar Weight") {
                HStack {
                    Text(WeightConverter.unitLabel(useKg) == "kg" ? "Olympic Bar" : "Olympic Bar")
                    Spacer()
                    Text("\(barWeight.formatted()) \(WeightConverter.unitLabel(useKg))").foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Plate Calculator")
    }

    private func plateCircle(_ weight: Double) -> some View {
        let colors: [Double: Color] = [
            25: .red, 20: .blue, 15: .yellow, 10: .green,
            5: .white, 2.5: .red, 1.25: .white,
            45: .blue, 35: .yellow, 25.0: .green, 10.0: .white
        ]
        let color = colors[weight] ?? .gray
        return ZStack {
            Circle().fill(color).frame(width: 32, height: 32)
            Circle().stroke(Color.black.opacity(0.2), lineWidth: 1).frame(width: 32, height: 32)
            Text(weight < 10 ? weight.formatted() : "\(Int(weight))")
                .font(.caption2).fontWeight(.bold)
                .foregroundStyle(color == .white ? .black : .white)
        }
    }
}
