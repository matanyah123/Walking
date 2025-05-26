import CoreLocation
import WidgetKit
import SwiftUI
import MapKit
import UIKit

struct WalkHistoryView: View {
    @State private var walkHistory: [WalkData] = loadSavedWalks()

    private var groupedWalks: [(String, [WalkData])] {
        let sortedWalks = walkHistory.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sortedWalks) { walk in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: walk.date)
        }
        return grouped.sorted { $0.key > $1.key }
    }

  var body: some View {
    NavigationStack {
      List {
        ForEach(groupedWalks, id: \.0) { date, walks in
          Section(header: Text(formattedDisplayDate(from: date)).font(.headline)) {
            ForEach(walks) { walk in
              NavigationLink(destination: WalkDetailView(walk: walk)) {
                VStack(alignment: .leading) {
                  Text("\(walk.distance, specifier: "%.2f") meters")
                    .font(.body)
                  Text("Steps: \(walk.steps)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 6)
              }
              .swipeActions(edge: .trailing) {
                  Button(role: .destructive) {
                      deleteWalk(walk)
                  } label: {
                      Label("Delete", systemImage: "trash")
                  }.tint(.red)
              }
              .swipeActions(edge: .leading) {
                  Button {
                      shareWalkSnapshot(walk: walk)
                  } label: {
                      Label("Share", systemImage: "square.and.arrow.up")
                  }
              }
            }
          }
        }
      }
      .navigationTitle("Walk History")
    }
    .onAppear {
      walkHistory = loadSavedWalks()
    }
  }

    private func deleteWalk(_ walk: WalkData) {
        walkHistory.removeAll { $0.id == walk.id }
        saveWalks(walkHistory)
    }

  private func saveWalks(_ walks: [WalkData]) {
      if let encoded = try? JSONEncoder().encode(walks) {
          // Save to main app's UserDefaults
          UserDefaults.standard.set(encoded, forKey: "walkHistory")

          // Save the latest walk to App Group for widget access
          if let latest = walks.sorted(by: { $0.date > $1.date }).first,
             let latestEncoded = try? JSONEncoder().encode(latest),
             let sharedDefaults = UserDefaults(suiteName: "group.com.matanyah.WalkTracker") {
              sharedDefaults.set(latestEncoded, forKey: "latestWalk")
              sharedDefaults.synchronize()

              // Generate and save map snapshot for widget
              createMapSnapshotForWidget(walk: latest) { image in
                  if let image = image,
                     let imageData = image.jpegData(compressionQuality: 0.8) {
                      sharedDefaults.set(imageData, forKey: "latestWalkMapImage")
                      sharedDefaults.synchronize()

                      // Refresh widgets to show new data
                      #if os(iOS)
                      WidgetCenter.shared.reloadAllTimelines()
                      #endif
                  }
              }
          }
      }
  }

  func createMapSnapshotForWidget(walk: WalkData, completion: @escaping (UIImage?) -> Void) {
      guard !walk.route.isEmpty else {
          completion(nil)
          return
      }

      let options = MKMapSnapshotter.Options()
      let coordinates = walk.route.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }

      // Calculate the region that fits the route
      var rect = MKMapRect.null
      for coord in coordinates {
          let point = MKMapPoint(coord)
          rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
      }

      // Add padding
      let padding = 0.2 // 20% padding
      let widthPadding = rect.size.width * padding
      let heightPadding = rect.size.height * padding
      rect = rect.insetBy(dx: -widthPadding, dy: -heightPadding)

      options.region = MKCoordinateRegion(rect)
      options.size = CGSize(width: 400, height: 400) // Larger size for better quality
      options.mapType = .standard
      options.showsBuildings = true

      let snapshotter = MKMapSnapshotter(options: options)
      snapshotter.start { snapshot, error in
          guard let snapshot = snapshot, error == nil else {
              completion(nil)
              return
          }

          // Draw the route on the snapshot
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

private func loadSavedWalks() -> [WalkData] {
    if let savedData = UserDefaults.standard.data(forKey: "walkHistory"),
       let walkHistory = try? JSONDecoder().decode([WalkData].self, from: savedData) {
        return walkHistory
    }
    return []
}

struct WalkDetailView: View {
    let walk: WalkData
    @State private var isMiniMapOpen = false
    @State private var isSharedViewOpen = false
    @State private var isViewReady = false
    @State private var shouldShareAfterLoad = false
  @State private var trackingMode: Int = 0

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ScrollView {
                if isLandscape {
                    landscapeView
                } else {
                    portraitView
                }
            }
            .background {
                Color.white.ignoresSafeArea()
                Color.black.opacity(0.85).ignoresSafeArea()
            }
            .scrollContentBackground(.hidden)
        }
        .sheet(isPresented: $isMiniMapOpen) {
            ZStack {
              MapView(route: walk.route.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }, showUserLocation: false, trackingMode: $trackingMode)
                    .ignoresSafeArea()
                VStack {
                    BlurView(style: .systemUltraThinMaterial)
                        .frame(width: 500, height: 25)
                        .overlay {
                            Capsule()
                                .foregroundColor(.gray)
                                .frame(width: 100, height: 10)
                        }
                    Spacer()
                }
            }
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
        .navigationTitle(formattedDate())
    }

    // Portrait layout
    private var portraitView: some View {
        VStack(spacing: 20) {
          WalkCard {
              HStack {
                  Image(systemName: "figure.walk")
                      .font(.title)
                  VStack(alignment: .leading) {
                      Text("Distance")
                          .font(.caption)
                          .foregroundColor(.secondary)
                      Text("\(walk.distance, specifier: "%.2f") m")
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
            MapView(route: walk.route.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }, showUserLocation: false,trackingMode: $trackingMode)
                  .frame(height: 200)
                  .cornerRadius(15)
                  .onTapGesture {
                      isMiniMapOpen = true
                  }
          }
          .frame(maxWidth: .infinity)

            infoCards
            Button {
                shareWalkSnapshot(walk: walk)
            } label: {
                Label("Share Walk", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(2.5)
            Spacer().frame(height: 60)
        }
        .padding()
    }

    // Landscape layout
    private var landscapeView: some View {
      HStack(alignment: .top, spacing: 20) {
        VStack(spacing: 20) {
          WalkCard {
            HStack {
              Image(systemName: "figure.walk")
                .font(.title)
              VStack(alignment: .leading) {
                Text("Distance")
                  .font(.caption)
                  .foregroundColor(.secondary)
                Text("\(walk.distance, specifier: "%.2f") m")
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
          infoCards
        }
        .frame(maxWidth: .infinity)
          WalkCard {
            MapView(route: walk.route.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }, showUserLocation: false, trackingMode: $trackingMode)
              .frame(height: 270)
              .cornerRadius(15)
              .onTapGesture {
                isMiniMapOpen = true
              }
          }
          .frame(maxWidth: .infinity)
      }
        .padding()
        .padding(.bottom, 100.0)
    }

    // Common cards
    private var infoCards: some View {
        Group {
            WalkCard {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Elevation Gain: \(walk.elevationGain, specifier: "%.2f") m")
                        Text("Elevation Loss: \(walk.elevationLoss, specifier: "%.2f") m")
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
}


/*
 #Preview {
  WalkHistoryView()
    .preferredColorScheme(.dark)
}

#Preview {
   var walkHistory: [WalkData] = loadSavedWalks()
   @State var isViewReady = false

   var groupedWalks: [(String, [WalkData])] {
      let sortedWalks = walkHistory.sorted { $0.date > $1.date }
      let grouped = Dictionary(grouping: sortedWalks) { walk in
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd"
          return formatter.string(from: walk.date)
      }
      return grouped.sorted { $0.key > $1.key }
  }

  if let latestGroup = groupedWalks.first,
     let firstWalk = latestGroup.1.first {
    Sharedview(walk: firstWalk, isViewReady: $isViewReady)
      .preferredColorScheme(.dark)
  }
}
*/

#Preview {
   var walkHistory: [WalkData] = loadSavedWalks()
   @State var isViewReady = false

   var groupedWalks: [(String, [WalkData])] {
      let sortedWalks = walkHistory.sorted { $0.date > $1.date }
      let grouped = Dictionary(grouping: sortedWalks) { walk in
          let formatter = DateFormatter()
          formatter.dateFormat = "yyyy-MM-dd"
          return formatter.string(from: walk.date)
      }
      return grouped.sorted { $0.key > $1.key }
  }

  if let latestGroup = groupedWalks.first,
     let firstWalk = latestGroup.1.first {
    WalkDetailView(walk: firstWalk)
      .preferredColorScheme(.dark)
  }
}
