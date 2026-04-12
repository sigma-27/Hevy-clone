import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var settingsArr: [UserSettings]
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appTheme") private var appTheme = "system"

    private var settings: UserSettings {
        if let s = settingsArr.first { return s }
        let s = UserSettings(); modelContext.insert(s); return s
    }

    var body: some View {
        List {
            Section("Units") {
                Toggle("Use Kilograms (kg)", isOn: Binding(
                    get: { settings.useKilograms },
                    set: { settings.useKilograms = $0 }
                ))
            }

            Section("Rest Timer") {
                HStack {
                    Text("Default Rest Time")
                    Spacer()
                    Stepper("\(settings.restTimerDefaultSeconds)s",
                            value: Binding(get: { settings.restTimerDefaultSeconds }, set: { settings.restTimerDefaultSeconds = $0 }),
                            in: 15...600, step: 15)
                }
                Toggle("Auto-Start After Set", isOn: Binding(
                    get: { settings.autoStartRestTimer },
                    set: { settings.autoStartRestTimer = $0 }
                ))
            }

            Section("Calculations") {
                Picker("1RM Formula", selection: Binding(
                    get: { settings.oneRMFormula },
                    set: { settings.oneRMFormula = $0 }
                )) {
                    ForEach(["Epley","Brzycki","Lander"], id: \.self) { Text($0).tag($0) }
                }

                Toggle("Show RPE Field", isOn: Binding(
                    get: { settings.showRPE },
                    set: { settings.showRPE = $0 }
                ))
            }

            Section("Appearance") {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }

            Section {
                HStack {
                    Text("Bar Weight")
                    Spacer()
                    if settings.useKilograms {
                        Stepper("\(settings.barWeightKg.formatted()) kg",
                                value: Binding(get: { settings.barWeightKg }, set: { settings.barWeightKg = $0 }),
                                in: 5...30, step: 2.5)
                    } else {
                        Stepper("\(settings.barWeightLbs.formatted()) lbs",
                                value: Binding(get: { settings.barWeightLbs }, set: { settings.barWeightLbs = $0 }),
                                in: 10...65, step: 5)
                    }
                }
                availablePlatesRow
            } header: {
                Text("Plate Calculator")
            } footer: {
                Text("Tap a plate to toggle it on or off.")
            }

            Section("About") {
                HStack {
                    AppIconView(size: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("IronLog").fontWeight(.semibold)
                        Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.leading, 6)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .onChange(of: settingsArr) { _, _ in try? modelContext.save() }
    }

    private var availablePlatesRow: some View {
        let allKg: [Double] = [1.25, 2.5, 5, 10, 15, 20, 25]
        let allLbs: [Double] = [2.5, 5, 10, 25, 35, 45]
        let all = settings.useKilograms ? allKg : allLbs
        let unit = settings.useKilograms ? "kg" : "lbs"
        return VStack(alignment: .leading, spacing: 8) {
            Text("Available Plates (\(unit))")
                .font(.subheadline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(all, id: \.self) { plate in
                        let isOn = settings.useKilograms
                            ? settings.availablePlatesKg.contains(plate)
                            : settings.availablePlatesLbs.contains(plate)
                        Button {
                            if settings.useKilograms {
                                if isOn { settings.availablePlatesKg.removeAll { $0 == plate } }
                                else { settings.availablePlatesKg.append(plate); settings.availablePlatesKg.sort() }
                            } else {
                                if isOn { settings.availablePlatesLbs.removeAll { $0 == plate } }
                                else { settings.availablePlatesLbs.append(plate); settings.availablePlatesLbs.sort() }
                            }
                        } label: {
                            Text(plate < 10 ? plate.formatted() : "\(Int(plate))")
                                .font(.caption).fontWeight(.semibold)
                                .frame(width: 44, height: 44)
                                .background(isOn ? Color.accentColor : Color(.tertiarySystemBackground))
                                .foregroundStyle(isOn ? .white : .secondary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
