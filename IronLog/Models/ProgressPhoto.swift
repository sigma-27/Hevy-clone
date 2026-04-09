import SwiftData
import Foundation

@Model
final class ProgressPhoto {
    @Attribute(.unique) var id: UUID
    var date: Date
    @Attribute(.externalStorage) var photoData: Data
    var notes: String
    var bodyAngle: String   // "front", "back", "side"

    init(id: UUID = UUID(), date: Date = Date(), photoData: Data, notes: String = "", bodyAngle: String = "front") {
        self.id = id
        self.date = date
        self.photoData = photoData
        self.notes = notes
        self.bodyAngle = bodyAngle
    }
}
