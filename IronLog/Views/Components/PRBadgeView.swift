import SwiftUI

struct PRBadgeView: View {
    var label: String = "PR"

    var body: some View {
        Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.yellow.opacity(0.25))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 1))
    }
}
