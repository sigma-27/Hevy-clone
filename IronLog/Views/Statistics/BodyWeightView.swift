import SwiftUI
import SwiftData
import Charts

struct BodyWeightView: View {
    @Query(sort: \BodyWeightEntry.date, order: .reverse) private var entries: [BodyWeightEntry]
    @Query private var settings: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @State private var showingAdd = false
    @State private var newWeight = ""
    @State private var newDate = Date()
    @State private var newNotes = ""

    private var useKg: Bool { settings.first?.useKilograms ?? true }
    private var chronological: [BodyWeightEntry] { entries.sorted { $0.date < $1.date } }

    var body: some View {
        List {
            if !chronological.isEmpty {
                Section {
                    Chart(chronological) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", WeightConverter.toDisplay(entry.weightKg, useKg: useKg))
                        )
                        .interpolationMethod(.catmullRom)
                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("Weight", WeightConverter.toDisplay(entry.weightKg, useKg: useKg))
                        )
                    }
                    .frame(height: 180)
                    .chartYAxisLabel(WeightConverter.unitLabel(useKg))
                }
            }

            Section {
                ForEach(entries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.subheadline)
                            if !entry.notes.isEmpty { Text(entry.notes).font(.caption).foregroundStyle(.secondary) }
                        }
                        Spacer()
                        Text(WeightConverter.formatted(entry.weightKg, useKg: useKg))
                            .font(.headline).fontWeight(.semibold)
                    }
                }
                .onDelete { offsets in
                    for i in offsets { modelContext.delete(entries[i]) }
                }
            }
        }
        .navigationTitle("Body Weight")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) { addSheet }
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                Section("Weight") {
                    HStack {
                        TextField("0.0", text: $newWeight).keyboardType(.decimalPad)
                        Text(WeightConverter.unitLabel(useKg)).foregroundStyle(.secondary)
                    }
                }
                Section("Date") { DatePicker("Date", selection: $newDate, displayedComponents: .date).labelsHidden() }
                Section("Notes") { TextField("Optional notes", text: $newNotes) }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let v = Double(newWeight) else { return }
                        let kg = WeightConverter.fromDisplay(v, useKg: useKg)
                        modelContext.insert(BodyWeightEntry(weightKg: kg, date: newDate, notes: newNotes))
                        showingAdd = false
                        newWeight = ""
                    }
                    .fontWeight(.semibold)
                    .disabled(Double(newWeight) == nil)
                }
            }
        }
    }
}
