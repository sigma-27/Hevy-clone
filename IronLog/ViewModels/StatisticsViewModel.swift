import SwiftUI

@Observable
class StatisticsViewModel {
    var selectedExercise: Exercise?
    var bodyWeightRange: TimeRange = .threeMonths

    enum TimeRange: String, CaseIterable {
        case oneMonth = "1M"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case allTime = "All"
    }
}
