import SwiftUI

@Observable
class HistoryViewModel {
    var selectedDate: Date?
    var viewMode: ViewMode = .list

    enum ViewMode { case list, calendar }
}
