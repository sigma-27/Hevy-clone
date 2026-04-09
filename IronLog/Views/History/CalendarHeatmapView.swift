import SwiftUI
import SwiftData

struct CalendarHeatmapView: View {
    var workouts: [Workout]
    @State private var selectedMonth = Calendar.current.startOfMonth(for: Date())

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let dayLabels = ["S","M","T","W","T","F","S"]

    private var daysInMonth: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth) else { return [] }
        let firstWeekday = calendar.component(.weekday, from: selectedMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: selectedMonth))
        }
        return days
    }

    private var volumeByDate: [Date: Double] {
        Dictionary(grouping: workouts.filter { !$0.isInProgress }) {
            calendar.startOfDay(for: $0.startTime)
        }.mapValues { $0.reduce(0) { $0 + $1.totalVolumeKg } }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
                Spacer()
                Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.headline)
                Spacer()
                Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
                    .disabled(selectedMonth >= calendar.startOfMonth(for: Date()))
            }
            .padding(.horizontal)

            // Day headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(dayLabels, id: \.self) { d in
                    Text(d).font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)

            // Day cells
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth.indices, id: \.self) { i in
                    if let date = daysInMonth[i] {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func dayCell(_ date: Date) -> some View {
        let volume = volumeByDate[calendar.startOfDay(for: date)] ?? 0
        let isToday = calendar.isDateInToday(date)
        let intensity = min(1.0, volume / 5000)
        return VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.caption2)
                .frame(maxWidth: .infinity).frame(height: 36)
                .background(volume > 0 ? Color.accentColor.opacity(0.2 + intensity * 0.6) : Color.clear)
                .overlay(isToday ? RoundedRectangle(cornerRadius: 6).stroke(Color.accentColor, lineWidth: 1.5) : nil)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    private func changeMonth(_ delta: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: delta, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let comps = dateComponents([.year, .month], from: date)
        return self.date(from: comps) ?? date
    }
}
