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
                            photoThumbnail(photo)
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
                        showingAdd = false
                    }.fontWeight(.semibold).disabled(pendingImageData == nil)
                }
            }
        }
    }
}
