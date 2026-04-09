import SwiftUI

struct MuscleGroupFilterView: View {
    @Binding var selectedMuscle: String?
    private let muscles = ["chest","back","shoulders","biceps","triceps","quadriceps","hamstrings","glutes","abs","calves","lower_back","traps"]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip("All", isSelected: selectedMuscle == nil) { selectedMuscle = nil }
                ForEach(muscles, id: \.self) { m in
                    filterChip(m.replacingOccurrences(of: "_", with: " ").capitalized,
                               isSelected: selectedMuscle == m) { selectedMuscle = m }
                }
            }
            .padding(.horizontal)
        }
    }

    private func filterChip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
