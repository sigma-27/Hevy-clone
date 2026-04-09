import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Query(sort: \Routine.name) private var routines: [Routine]
    @Environment(\.modelContext) private var modelContext
    @State private var showingCreate = false

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    EmptyStateView(title: "No Routines", message: "Create a routine to plan your workouts in advance.", systemImage: "list.bullet.clipboard")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(routines) { routine in
                            NavigationLink(destination: RoutineDetailView(routine: routine)) {
                                routineRow(routine)
                            }
                        }
                        .onDelete(perform: deleteRoutines)
                    }
                }
            }
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingCreate) { CreateRoutineView() }
        }
    }

    private func routineRow(_ routine: Routine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name).font(.subheadline).fontWeight(.semibold)
            Text("\(routine.exercises.count) exercises · \(scheduledDaysLabel(routine))")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func scheduledDaysLabel(_ routine: Routine) -> String {
        guard !routine.scheduledDays.isEmpty else { return "Unscheduled" }
        let days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        return routine.scheduledDays.sorted().map { days[$0] }.joined(separator: ", ")
    }

    private func deleteRoutines(at offsets: IndexSet) {
        for i in offsets { modelContext.delete(routines[i]) }
    }
}
