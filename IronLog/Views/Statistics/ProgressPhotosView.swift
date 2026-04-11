import SwiftUI
import SwiftData
import PhotosUI

struct ProgressPhotosView: View {
    @Query(sort: \ProgressPhoto.date, order: .reverse) private var photos: [ProgressPhoto]
    @Environment(\.modelContext) private var modelContext
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingAdd = false
    @State private var selectedAngle = "front"
    @State private var photoNotes = ""
    @State private var pendingImageData: Data?
    @State private var selectedPhoto: ProgressPhoto?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        Group {
            if photos.isEmpty {
                EmptyStateView(title: "No Progress Photos", message: "Track your physique changes over time.", systemImage: "photo.stack")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(photos) { photo in
                            Button { selectedPhoto = photo } label: {
                                photoThumbnail(photo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .navigationTitle("Progress Photos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: pickerItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    pendingImageData = data
                    showingAdd = true
                }
            }
        }
        .sheet(isPresented: $showingAdd) { addSheet }
        .sheet(item: $selectedPhoto) { photo in
            PhotoDetailView(photo: photo) {
                modelContext.delete(photo)
                try? modelContext.save()
                selectedPhoto = nil
            }
        }
    }

    private func photoThumbnail(_ photo: ProgressPhoto) -> some View {
        Group {
            if let uiImage = UIImage(data: photo.photoData) {
                Image(uiImage: uiImage)
                    .resizable().scaledToFill()
                    .frame(height: 120).clipped()
            } else {
                Color.gray.frame(height: 120)
            }
        }
    }

    private var addSheet: some View {
        NavigationStack {
            Form {
                if let data = pendingImageData, let img = UIImage(data: data) {
                    Section { Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 200) }
                }
                Section("Body Angle") {
                    Picker("Angle", selection: $selectedAngle) {
                        Text("Front").tag("front")
                        Text("Back").tag("back")
                        Text("Side").tag("side")
                    }.pickerStyle(.segmented)
                }
                Section("Notes") { TextField("Optional notes", text: $photoNotes) }
            }
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Cancel") { showingAdd = false } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let data = pendingImageData else { return }
                        modelContext.insert(ProgressPhoto(photoData: data, notes: photoNotes, bodyAngle: selectedAngle))
                        photoNotes = ""
                        selectedAngle = "front"
                        pendingImageData = nil
                        pickerItem = nil
                        showingAdd = false
                    }.fontWeight(.semibold).disabled(pendingImageData == nil)
                }
            }
        }
    }
}

// MARK: - Full-screen photo detail

private struct PhotoDetailView: View {
    var photo: ProgressPhoto
    var onDelete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let img = UIImage(data: photo.photoData) {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(maxWidth: .infinity)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label(photo.date.formatted(date: .long, time: .omitted), systemImage: "calendar")
                                .font(.subheadline)
                            Spacer()
                            Text(photo.bodyAngle.capitalized)
                                .font(.caption).fontWeight(.semibold)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(.accentColor)
                                .clipShape(Capsule())
                        }
                        if !photo.notes.isEmpty {
                            Text(photo.notes)
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle(photo.date.formatted(date: .abbreviated, time: .omitted))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) { showingDeleteConfirm = true } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .confirmationDialog("Delete Photo?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { onDelete() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
