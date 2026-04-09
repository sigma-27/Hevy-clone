import SwiftUI

struct MuscleGroupBadge: View {
    var muscle: String
    var isPrimary: Bool = true

    var body: some View {
        Text(muscle.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isPrimary ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
            .foregroundStyle(isPrimary ? .blue : .secondary)
            .clipShape(Capsule())
    }
}
