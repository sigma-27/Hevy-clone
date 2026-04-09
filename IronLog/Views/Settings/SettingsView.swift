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
}
