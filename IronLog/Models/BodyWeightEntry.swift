import SwiftData
import Foundation

@Model
final class BodyWeightEntry {
    @Attribute(.unique) var id: UUID
    var weightKg: Double
    var date: Date
    var notes: String

    init(id: UUID = UUID(), weightKg: Double, date: Date = Date(), notes: String = "") {
        self.id = id
        self.weightKg = weightKg
        self.date = date
        self.notes = notes
    }
}
