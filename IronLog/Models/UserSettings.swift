import SwiftData
import Foundation

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var useKilograms: Bool
    var restTimerDefaultSeconds: Int
    var autoStartRestTimer: Bool
    var oneRMFormula: String   // "Epley", "Brzycki", "Lander"
    var showRPE: Bool
    var availablePlatesKg: [Double]
    var availablePlatesLbs: [Double]
    var barWeightKg: Double
    var barWeightLbs: Double

    init(id: UUID = UUID()) {
        self.id = id
        self.useKilograms = true
        self.restTimerDefaultSeconds = 90
        self.autoStartRestTimer = true
        self.oneRMFormula = "Epley"
        self.showRPE = true
        self.availablePlatesKg = [1.25, 2.5, 5.0, 10.0, 15.0, 20.0, 25.0]
        self.availablePlatesLbs = [2.5, 5.0, 10.0, 25.0, 35.0, 45.0]
        self.barWeightKg = 20.0
        self.barWeightLbs = 45.0
    }
}

struct UserSettingsManager {
    @MainActor
    static func ensureExists(modelContainer: ModelContainer) async {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<UserSettings>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count == 0 {
            context.insert(UserSettings())
            try? context.save()
        }
    }
}
