import SwiftUI
import SwiftData

struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.modelContainer) private var modelContainer
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var exportURL: URL?
    @State private var showingExportShare = false
    @State private var showingImportConfirm = false
    @State private var importURL: URL?
    @State private var statusMessage = ""
    @State private var showingStatus = false

    var body: some View {
        List {
            Section {
                Text("Export a full backup of your workouts, exercises, and routines as a JSON file. You can save it to Files, AirDrop it, or upload it to Google Drive.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            Section("Backup") {
                Button {
                    exportData()
                } label: {
                    Label("Export Backup (JSON)", systemImage: "arrow.up.doc.fill")
                }
                .disabled(isExporting)
            }

            Section("Restore") {
                Button {
                    isImporting = true
                } label: {
                    Label("Import Backup (JSON)", systemImage: "arrow.down.doc.fill")
                }
                .foregroundStyle(.orange)
            }

            Section {
                Label("Progress photos are stored locally only and not included in the backup.", systemImage: "info.circle")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Backup & Restore")
        .sheet(isPresented: $showingExportShare) {
            if let url = exportURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url): importURL = url; showingImportConfirm = true
            case .failure: statusMessage = "Failed to open file."; showingStatus = true
            }
        }
        .confirmationDialog("Replace all data?", isPresented: $showingImportConfirm, titleVisibility: .visible) {
            Button("Import & Replace", role: .destructive) {
                if let url = importURL { importData(from: url) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace ALL your current data with the backup. This cannot be undone.")
        }
        .alert("Backup", isPresented: $showingStatus) {
            Button("OK") {}
        } message: {
            Text(statusMessage)
        }
    }

    private func exportData() {
        isExporting = true
        Task {
            do {
                let data = try await ExportService.exportJSON(modelContainer: modelContainer)
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("IronLog_backup_\(Date().formatted(.iso8601)).json")
                try data.write(to: url)
                await MainActor.run {
                    exportURL = url
                    showingExportShare = true
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Export failed: \(error.localizedDescription)"
                    showingStatus = true
                    isExporting = false
                }
            }
        }
    }

    private func importData(from url: URL) {
        Task {
            do {
                let data = try Data(contentsOf: url)
                try await ExportService.importJSON(data, into: modelContainer)
                await MainActor.run {
                    statusMessage = "Data imported successfully."
                    showingStatus = true
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Import failed: \(error.localizedDescription)"
                    showingStatus = true
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
