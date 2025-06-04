//
//  Sharedview.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import SwiftUI
import CoreLocation

@MainActor
func shareWalkSnapshot(walk: WalkData) {
    // Create a temporary view controller to host our map
    let mapSnapshotView = UIHostingController(
        rootView: Sharedview(walk: walk, isViewReady: .constant(true))
    )

    // Size it appropriately
    mapSnapshotView.view.frame = UIScreen.main.bounds

    // Add it to the view hierarchy temporarily (but don't show it)
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let window = windowScene.windows.first {
        window.addSubview(mapSnapshotView.view)

        // Give the map time to load - MapKit needs this
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Now capture the fully loaded view
            let renderer = UIGraphicsImageRenderer(size: mapSnapshotView.view.bounds.size)
            let screenshot = renderer.image { _ in
                mapSnapshotView.view.drawHierarchy(in: mapSnapshotView.view.bounds, afterScreenUpdates: true)
            }

            // Remove our temporary view
            mapSnapshotView.view.removeFromSuperview()

            // Share the screenshot
            let activityVC = UIActivityViewController(activityItems: [screenshot], applicationActivities: nil)

            if let rootVC = windowScene.windows.first?.rootViewController {
                // If rootVC is presenting something, use the presented controller
                let presentingVC = rootVC.presentedViewController ?? rootVC

                // On iPad, set the popover presentation controller
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = presentingVC.view
                    popover.sourceRect = CGRect(x: presentingVC.view.bounds.midX,
                                             y: presentingVC.view.bounds.midY,
                                             width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }

                presentingVC.present(activityVC, animated: true)
            }
        }
    }
}

struct Sharedview: View {
  let walk: WalkData
  @State private var isMiniMapOpen = false
  @Binding var isViewReady: Bool // Use a binding to track view readiness
  @State private var trackingMode: Int = 0
  @AppStorage("darkMode", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var darkMode: Bool = true
  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var unit: Bool = true
  var body: some View {
    ZStack {
      MapView(route: walk.route.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }, showUserLocation: false, trackingMode: $trackingMode)
        .ignoresSafeArea(.all)
      BlurView(style: darkMode ? .systemUltraThinMaterialDark : .systemThinMaterialLight).ignoresSafeArea(.all)
      VStack(alignment: .leading) {
        // Distance and Time
        HStack(alignment: .bottom) {
          VStack(alignment: .leading) {
            Text("Distance")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("\(walk.distance, specifier: "%.2f") \(unit ? "km" : "mi")")
              .font(.headline)
              .bold()
          }
          Divider()
            .background(Color.white)
            .frame(height: 40)
          VStack(alignment: .leading) {
            Text("Time")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("\(formattedDuration)")
              .font(.headline)
              .bold()
          }
          Divider()
            .background(Color.white)
            .frame(height: 40)
          // Steps
          VStack(alignment: .leading) {
            Text("Steps")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("\(walk.steps)")
              .font(.headline)
              .bold()
          }
          Spacer()
          // Date
          VStack(alignment: .trailing){
            Text("Date")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text(formattedDate)
              .font(.headline)
              .bold()
          }
          .padding(.trailing)
        }
        .padding(.leading)

        MapView(route: walk.route.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }, showUserLocation: false, trackingMode: $trackingMode)
          .innerShadow(radius: 20)
          .onAppear {
            // Simulate loading; add custom logic if needed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
              isViewReady = true // Mark the view as ready after loading
            }
          }
          .cornerRadius(20)
          .padding(.horizontal)
          .frame(width: 400.0, height: 700.0)

        HStack(alignment: .top){
          Text("Walking")
            .font(.subheadline)
            .bold()
          Image("Vibrant Orange")
            .resizable()
            .cornerRadius(5)
            .scaledToFit()
        }
        .padding(.leading)
        .frame(height: 20)
      }
      .padding()
    }
    .colorScheme(darkMode ? .dark : .light)
  }

  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: walk.date)
  }
  private var formattedDuration: String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = walk.duration >= 3600 ? [.hour, .minute] : [.minute, .second]
    return formatter.string(from: walk.duration) ?? "0m"
}
}

struct WalkCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack {
            content
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 4)
    }
}

private func loadSavedWalks() -> [WalkData] {
    if let savedData = UserDefaults.standard.data(forKey: "walkHistory"),
       let walkHistory = try? JSONDecoder().decode([WalkData].self, from: savedData) {
        return walkHistory
    }
    return []
}

#Preview {
  struct PreviewWrapper: View {
    @State private var isViewReady = false
    var walkHistory: [WalkData] = loadSavedWalks()

    var body: some View {
      Group {
        if let firstWalk = getLatestWalk() {
          Sharedview(walk: firstWalk, isViewReady: $isViewReady)
            .preferredColorScheme(.dark)
        } else {
          Text("No walks available")
            .preferredColorScheme(.dark)
        }
      }
    }

    private func getLatestWalk() -> WalkData? {
      let sortedWalks = walkHistory.sorted { $0.date > $1.date }
      return sortedWalks.first
    }
  }

  return PreviewWrapper()
}
