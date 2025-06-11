//
//  WalkHistoryView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import CoreLocation
import WidgetKit
import SwiftData
import LazyPager
import PhotosUI
import SwiftUI
import MapKit
import Photos
import UIKit

struct WalkHistoryView: View {
  @Environment(\.modelContext) private var modelContext

  @Query(sort: \WalkData.date, order: .reverse) private var walkHistory: [WalkData]

  private var groupedWalks: [(String, [WalkData])] {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    let grouped = Dictionary(grouping: walkHistory) { walk in
      formatter.string(from: walk.date)
    }
    return grouped.sorted { $0.key > $1.key }
  }

  @State private var showDeleteConfirmation = false
  @State private var walkToDelete: WalkData?
  @State private var selectedWalkForEditing: WalkData?
  @State private var editingName = ""

  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var unit: Bool = true

  var body: some View {
    NavigationStack {
      List {
        if !groupedWalks.isEmpty {
          ForEach(groupedWalks, id: \.0) { date, walks in
            Section(header: Text(formattedDisplayDate(from: date)).font(.headline)) {
              ForEach(walks) { walk in
                NavigationLink(destination: WalkDetailView(walk: walk)) {
                  VStack(alignment: .leading, spacing: 4) {
                    // Display walk name or fallback to default format
                    Text(displayName(for: walk))
                      .font(.body)
                      .fontWeight(.medium)

                    // Always show distance and steps as secondary info
                    Text("\(walk.distance, specifier: "%.2f") \(unit ? "meters" : "miles") • \(walk.steps) steps")
                      .font(.caption)
                      .foregroundColor(.secondary)

                    // Show duration as well
                    Text(walk.formattedDuration)
                      .font(.caption2)
                      .foregroundColor(.secondary)
                  }
                  .padding(.vertical, 6)
                }
                .swipeActions(edge: .trailing) {
                  Button(role: .destructive) {
                    walkToDelete = walk
                    showDeleteConfirmation = true
                  } label: {
                    Label("Delete", systemImage: "trash").tint(.red)
                  }
                  .tint(.red)
                }
                .swipeActions(edge: .leading) {
                  Button {
                    shareWalkSnapshot(walk: walk)
                  } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                  }
                  Button {
                    selectedWalkForEditing = walk
                    editingName = walk.name ?? ""
                  } label: {
                    Label("Edit", systemImage: "pencil")
                  }.tint(.orange)
                }
              }
            }
          }
        } else {
          ContentUnavailableView(
            "No Recent Walks",
            systemImage: "figure.walk.circle",
            description: Text("Start tracking your walks to see them here")
          )
        }
      }
      .navigationTitle("Walk History")
      .safeAreaInset(edge: .bottom) {
        Color.clear.frame(height: 80)
      }
    }
    .alert("Are you sure?", isPresented: $showDeleteConfirmation, presenting: walkToDelete) { walk in
      Button("Delete", role: .destructive) {
        deleteWalk(walk)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      }
      Button("Cancel", role: .cancel) { }
    } message: { _ in
      Text("This action cannot be undone.")
    }
    .sheet(item: $selectedWalkForEditing) { walk in
      NavigationView {
        VStack(spacing: 20) {
          Text("Edit Walk Name")
            .font(.title2)
            .fontWeight(.semibold)

          TextField("Enter a name", text: $editingName)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)

          Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
              selectedWalkForEditing = nil
            }
          }
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Save") {
              saveWalkName(walk: walk, newName: editingName)
              selectedWalkForEditing = nil
            }
          }
        }
      }
    }
  }

  // Helper function to get display name for a walk
  private func displayName(for walk: WalkData) -> String {
    return walk.name ?? "Walk on \(formattedDate(walk.date))"
  }

  // Helper function to format date for walk names
  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }

  private func deleteWalk(_ walk: WalkData) {
    modelContext.delete(walk)
    do {
      try modelContext.save()
      // Optional: update widget after deleting
      WidgetCenter.shared.reloadAllTimelines()
    } catch {
      print("Failed to delete walk: \(error)")
    }
  }

  private func saveWalkName(walk: WalkData, newName: String) {
    walk.name = newName.isEmpty ? nil : newName
    do {
      try modelContext.save()
    } catch {
      print("Failed to save walk name: \(error)")
    }
  }

  func createMapSnapshotForWidget(walk: WalkData, completion: @escaping (UIImage?) -> Void) {
    guard !walk.route.isEmpty else {
      completion(nil)
      return
    }

    let options = MKMapSnapshotter.Options()
    let coordinates = walk.route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

    var rect = MKMapRect.null
    for coord in coordinates {
      let point = MKMapPoint(coord)
      rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
    }

    let padding = 0.2
    let widthPadding = rect.size.width * padding
    let heightPadding = rect.size.height * padding
    rect = rect.insetBy(dx: -widthPadding, dy: -heightPadding)

    options.region = MKCoordinateRegion(rect)
    options.size = CGSize(width: 400, height: 400)
    options.mapType = .standard
    options.showsBuildings = true

    let snapshotter = MKMapSnapshotter(options: options)
    snapshotter.start { snapshot, error in
      guard let snapshot = snapshot, error == nil else {
        completion(nil)
        return
      }

      UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, snapshot.image.scale)
      snapshot.image.draw(at: .zero)

      if let context = UIGraphicsGetCurrentContext() {
        context.setLineWidth(5)
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        let path = UIBezierPath()
        var firstPoint = true

        for coordinate in coordinates {
          let point = snapshot.point(for: coordinate)

          if firstPoint {
            path.move(to: point)
            firstPoint = false
          } else {
            path.addLine(to: point)
          }
        }

        path.stroke()
      }

      let finalImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()

      completion(finalImage)
    }
  }

  private func formattedDisplayDate(from isoDate: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    if let date = formatter.date(from: isoDate) {
      formatter.dateStyle = .medium
      return formatter.string(from: date)
    }
    return isoDate
  }
}

struct WalkDetailView: View {
  let walk: WalkData
  @Environment(\.modelContext) private var modelContext
  @State private var loadedImages: [UIImage] = []
  @State private var isLoadingImages = false
  @State private var isMiniMapOpen = false
  @State private var isSharedViewOpen = false
  @State private var isViewReady = false
  @State private var shouldShareAfterLoad = false
  @State private var trackingMode: Int = 0
  @State private var isEditingName = false
  @State private var editingName: String = ""
  @State private var showImageSheet = false
  @State private var selectedImage: WalkImage?
  @AppStorage("darkMode", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var darkMode: Bool = true
  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var unit: Bool = true

  // Computed property for display name (not @State)
  private var displayName: String {
    return walk.name ?? "Walk on \(formattedDate())"
  }

  var body: some View {
    NavigationStack {
        portraitView
        .onAppear {
          if !isViewReady {
            loadWalkImages()
          }
          // Initialize editing name when view appears
          editingName = walk.name ?? ""
        }
      .sheet(isPresented: $isSharedViewOpen) {
        Sharedview(walk: walk, isViewReady: $isViewReady)
      }
      .onChange(of: isViewReady) {
        if isViewReady && shouldShareAfterLoad {
          shareWalkSnapshot(walk: walk)
          shouldShareAfterLoad = false
          isSharedViewOpen = false
          isViewReady = false
        }
      }
      .navigationTitle(displayName)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          HStack{
            Button {
              shareWalkSnapshot(walk: walk)
            } label: {
              Image(systemName: "square.and.arrow.up")
                .foregroundColor(.accentFromSettings)
            }
            Button {
              isEditingName = true
            } label: {
              Image(systemName: "pencil")
                .foregroundColor(.accentFromSettings)
            }
          }
        }
      }
      .sheet(isPresented: $isEditingName) {
        NavigationView {
          VStack(spacing: 20) {
            Text("Edit Walk Name")
              .font(.title2)
              .fontWeight(.semibold)

            TextField("Enter a name", text: $editingName)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .padding(.horizontal)

            Spacer()
          }
          .padding()
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("Save") {
                saveWalkName(walk: walk, newName: editingName)
              }
            }
          }
        }
      }
    }
  }

  // Portrait layout
  private var portraitView: some View {
    ScrollView{
      VStack(spacing: 20) {
        WalkCard {
          HStack {
            Image(systemName: "figure.walk")
              .font(.title)
            VStack(alignment: .leading) {
              Text("Distance")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(walk.distance, specifier: "%.2f") \(unit ? "me" : "mi")")
                .font(.headline)
            }
            Spacer()
            VStack(alignment: .trailing) {
              Text("Steps")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("\(walk.steps)")
                .font(.headline)
            }
          }
        }

        WalkCard {
          NavigationLink{
            MapView(route: walk.route.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }, showUserLocation: false, trackingMode: $trackingMode, showImages: true, images: walk.walkImages, showImageSheet: $showImageSheet, selectedImage: $selectedImage)
              .ignoresSafeArea()
              .colorScheme(darkMode ? .dark : .light)
              .sheet(isPresented: $showImageSheet) {
                if let selectedImage = selectedImage,
                   let imageIndex = walk.walkImages.firstIndex(where: { $0.id == selectedImage.id }),
                   imageIndex < loadedImages.count,
                   loadedImages[imageIndex] != nil {
                  PhotoPagerView(
                    images: loadedImages.compactMap { $0 }, // Only non-nil images
                    startIndex: loadedImages.prefix(upTo: imageIndex).compactMap { $0 }.count
                  )
                } else {
                  // Fallback view when image can't be found
                  VStack(spacing: 20) {
                    Image(systemName: "photo")
                      .font(.system(size: 60))
                      .foregroundColor(.gray)

                    Text("Image Not Available")
                      .font(.title2)
                      .foregroundColor(.secondary)

                    Button("Close") {
                      showImageSheet = false
                      selectedImage = nil
                    }
                    .buttonStyle(.borderedProminent)
                  }
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
                  .background(Color.black)
                  .presentationDetents([.medium])
                }
              }
          } label: {
            MapView(route: walk.route.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }, showUserLocation: false,trackingMode: $trackingMode, showImageSheet: $showImageSheet, selectedImage: $selectedImage)
              .frame(height: 200)
              .cornerRadius(15)
              .overlay(
                Color.clear
                  .contentShape(Rectangle()) // Make overlay cover full frame
                  .allowsHitTesting(true)    // Blocks interaction on the map beneath
              )
          }

        }
        .frame(maxWidth: .infinity)

        infoCards
        VStack(alignment: .leading, spacing: 12) {
          HStack {
            Text("Photos")
              .font(.title2)
              .fontWeight(.bold)

            Spacer()

            Text("\(walk.walkImages.count) photo\(walk.walkImages.count == 1 ? "" : "s")")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          if isLoadingImages {
            VStack(spacing: 8) {
              Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .foregroundColor(.gray)

              Text("Image missing")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 100)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
          } else {
            // In WalkDetailView, modify the PhotoGridView usage:

            PhotoGridView(
              images: loadedImages,
              onImageDelete: { index in
                walk.walkImages.remove(at: index)
                loadedImages.remove(at: index)
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
              },
              onImagesAdded: { newImages in
                // Add new images to the loaded images array first
                loadedImages.append(contentsOf: newImages)

                // Save each image to the Photos library and create WalkImage objects
                for image in newImages {
                  if let imageData = image.jpegData(compressionQuality: 0.8) {
                    PHPhotoLibrary.requestAuthorization { status in
                      guard status == .authorized else {
                        print("Photo library access not authorized")
                        return
                      }
                      PHPhotoLibrary.shared().performChanges({
                        let options = PHAssetResourceCreationOptions()
                        let creationRequest = PHAssetCreationRequest.forAsset()
                        creationRequest.addResource(with: .photo, data: imageData, options: options)
                      }, completionHandler: { success, error in
                        if let error = error {
                          print("Error saving gallery photo: \(error)")
                        } else if success {
                          // Fetch the newest photo
                          let fetchOptions = PHFetchOptions()
                          fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                          fetchOptions.fetchLimit = 1
                          let result = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                          if let asset = result.firstObject {
                            DispatchQueue.main.async {
                              let walkImage = WalkImage(
                                imageType: .gallery, // Keep as .gallery to distinguish from camera photos
                                localIdentifier: asset.localIdentifier, // This is the key fix
                                fileURL: nil // Don't need fileURL for Photos library images
                              )
                              walk.walkImages.append(walkImage)
                              // Don't call loadWalkImages() here since we already added to loadedImages
                              UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                          }
                        }
                      })
                    }
                  }
                }
              }
            )
          }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
      }
      .padding()
    }.safeAreaInset(edge: .bottom) {
      Color.clear.frame(height: 80)
    }
  }

  // Common cards
  private var infoCards: some View {
    Group {
      WalkCard {
        HStack {
          VStack(alignment: .leading, spacing: 8) {
            Text("Elevation Gain: \(walk.elevationGain, specifier: "%.2f") \(unit ? "me" : "mi")")
            Text("Elevation Loss: \(walk.elevationLoss, specifier: "%.2f") \(unit ? "me" : "mi")")
          }
          Spacer()
        }
      }

      WalkCard {
        HStack {
          VStack(alignment: .leading, spacing: 8) {
            Text("Start Time: \(formattedTime(walk.startTime))")
            Text("End Time: \(formattedTime(walk.endTime))")
            Text("Duration: \(formattedDuration(walk.duration))")
          }
          Spacer()
        }
      }
    }
  }

  private func saveWalkName(walk: WalkData, newName: String) {
    walk.name = newName.isEmpty ? nil : newName
    do {
      try modelContext.save()
    } catch {
      print("Failed to save walk name: \(error)")
    }
  }

  private func formattedDate() -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: walk.date)
  }

  private func formattedDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = (Int(duration) % 3600) / 60
    let seconds = Int(duration) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  private func formattedTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func shareIfReady() {
    if isViewReady {
      print("Proceeding with share action!")
    } else {
      print("🚫 Sharedview is not ready yet.")
    }
  }

  private func loadWalkImages() {
    guard !walk.walkImages.isEmpty && loadedImages.isEmpty else { return }

    isLoadingImages = true
    let group = DispatchGroup()
    var tempImages: [UIImage?] = Array(repeating: nil, count: walk.walkImages.count)

    for (index, walkImage) in walk.walkImages.enumerated() {
      group.enter()

      // Both camera and gallery images now use localIdentifier
      if let identifier = walkImage.localIdentifier {
        // Load from Photos framework using localIdentifier
        print("Loading image from Photos library with identifier: \(identifier)")
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject

        if let asset = asset {
          let manager = PHImageManager.default()
          let options = PHImageRequestOptions()
          options.deliveryMode = .highQualityFormat
          options.isSynchronous = false

          manager.requestImage(
            for: asset,
            targetSize: CGSize(width: 1000, height: 1000),
            contentMode: .aspectFit,
            options: options
          ) { image, _ in
            tempImages[index] = image
            print("Successfully loaded image at index \(index)")
            group.leave()
          }
        } else {
          print("Asset not found for identifier: \(identifier)")
          group.leave()
        }
      } else if walkImage.imageType == .gallery, let fileURL = walkImage.fileURL {
        // Fallback for old gallery images that might still use fileURL
        print("Loading gallery image from file URL...")
        DispatchQueue.global(qos: .userInitiated).async {
          if FileManager.default.fileExists(atPath: fileURL.path) {
            if let imageData = try? Data(contentsOf: fileURL),
               let image = UIImage(data: imageData) {
              tempImages[index] = image
              print("Successfully loaded file-based image at index \(index)")
            } else {
              print("Failed to decode image data at index \(index)")
            }
          } else {
            print("File does not exist at path: \(fileURL.path)")
          }
          group.leave()
        }
      } else {
        print("No valid identifier or fileURL for image at index \(index)")
        group.leave()
      }
    }

    group.notify(queue: .main) {
      self.loadedImages = tempImages.compactMap { $0 }
      self.isLoadingImages = false
      print("Finished loading images. Total loaded: \(self.loadedImages.count)")
    }
  }

  private func saveWalkName() {
    let trimmedName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
    walk.name = trimmedName.isEmpty ? nil : trimmedName
    isEditingName = false
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }
}

struct PhotoGridView: View {
  let images: [UIImage?]
  let onImageDelete: (Int) -> Void
  let onImagesAdded: ([UIImage]) -> Void // New callback for adding images

  @State private var selectedImage: SelectedIndex? = nil
  @State private var selectedItems: [PhotosPickerItem] = []
  @State private var showingPhotoPicker = false

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      // Existing images
      ForEach(Array(images.enumerated()), id: \.offset) { index, image in
        if let image = images[index] {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipped()
            .cornerRadius(8)
            .onTapGesture {
              selectedImage = SelectedIndex(id: index)
            }
            .contextMenu {
              Button(role: .destructive) {
                onImageDelete(index)
              } label: {
                Label("Delete", systemImage: "trash")
                  .tint(.red)
              }
            }
        } else {
          VStack(spacing: 8) {
            Image(systemName: "photo")
              .resizable()
              .scaledToFit()
              .frame(width: 50, height: 50)
              .foregroundColor(.gray)

            Text("Image missing")
              .font(.caption)
              .multilineTextAlignment(.center)
              .foregroundColor(.secondary)
          }
          .frame(width: 100, height: 100)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(8)
        }
      }

      // Plus button
      Button(action: {
        showingPhotoPicker = true
      }) {
        ZStack {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .frame(width: 100, height: 100)

          Image(systemName: "plus")
            .font(.system(size: 30, weight: .light))
            .foregroundColor(.gray)
        }
      }
      .buttonStyle(PlainButtonStyle())
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.2))
          .frame(width: 100, height: 100)
        Text("+ Will make a\nduplicate\n(for now)")
          .font(.caption)
          .foregroundColor(.gray)
          .multilineTextAlignment(.center)
      }
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.gray.opacity(0.2))
          .frame(width: 100, height: 100)
        Text("You will need to\ncopy location manually.")
          .font(.caption)
          .foregroundColor(.gray)
          .multilineTextAlignment(.center)
      }
    }
    .fullScreenCover(item: $selectedImage) { selected in
      if let selectedImage = images[selected.id] {
        PhotoPagerView(
          images: images.compactMap { $0 },
          startIndex: images.prefix(upTo: selected.id).compactMap { $0 }.count
        )
      } else {
        VStack(spacing: 8) {
          Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .foregroundColor(.gray)

          Text("Image missing")
            .font(.largeTitle)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
      }
    }
    .photosPicker(
      isPresented: $showingPhotoPicker,
      selection: $selectedItems,
      maxSelectionCount: nil, // Allow unlimited selection
      matching: .images
    )
    .onChange(of: selectedItems) {
      Task {
        var newImages: [UIImage] = []

        for item in selectedItems {
          if let data = try? await item.loadTransferable(type: Data.self),
             let image = UIImage(data: data) {
            newImages.append(image)
          }
        }

        if !newImages.isEmpty {
          onImagesAdded(newImages)
        }

        // Clear selection for next time
        selectedItems = []
      }
    }
  }
}

struct SelectedIndex: Identifiable {
  let id: Int
}

struct PhotoPagerView: View {
  let images: [UIImage]
  let startIndex: Int

  @Environment(\.dismiss) var dismiss
  @State private var currentPage: Int
  @State var opacity: CGFloat = 1.0

  init(images: [UIImage], startIndex: Int) {
    self.images = images
    self.startIndex = startIndex
    _currentPage = State(initialValue: startIndex)
  }

  var body: some View {
    ZStack {
      Color.black.ignoresSafeArea(.all)
      LazyPager(data: images, page: $currentPage) { image in
        Image(uiImage: image)
          .resizable()
          .cornerRadius(20)
          .padding()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.black)
      }
      .zoomable(min: 1, max: 5)
      .onDismiss(backgroundOpacity: $opacity) {
        dismiss()
      }
      .overscroll { position in
        if position == .beginning {
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } else {
          UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
      }

      VStack {
        HStack{
          Spacer()
          // With this:
          ShareLink(item: Image(uiImage: images[currentPage]), preview: SharePreview("Photo")) {
            Image(systemName: "square.and.arrow.up.circle.fill")
              .font(.system(size: 30))
              .foregroundColor(.white.opacity(0.8))
          }
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 30))
              .foregroundColor(.white.opacity(0.8))
              .padding()
          }
        }
        HStack {
          Spacer()

          Text("\(currentPage + 1) of \(images.count)")
            .foregroundColor(.white)
            .font(.headline)

          Spacer()
        }
        Spacer()
      }
    }
  }
}

#Preview {
  WalkDetailView(walk: WalkData.dummy)
    .preferredColorScheme(.light)
}
