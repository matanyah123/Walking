import SwiftUI
import MapKit

private func mapTrackingMode(from intValue: Int) -> MKUserTrackingMode {
    switch intValue {
    case 1: return .follow
    case 2: return .followWithHeading
    default: return .none
    }
}

struct MapView: UIViewRepresentable {
    var route: [CLLocation]
    var currentLocation: CLLocation?
    var showUserLocation: Bool
    @Binding var trackingMode: Int
    // Reference to the parent ViewModel to track changes
    var viewModel: ContentViewModel?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = showUserLocation
        mapView.userTrackingMode = mapTrackingMode(from: trackingMode)
        mapView.mapType = .standard
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsBuildings = true

        // Add gesture recognizers to detect user interaction
        for recognizer in mapView.gestureRecognizers ?? [] {
            recognizer.addTarget(context.coordinator, action: #selector(Coordinator.handleGestureState(_:)))
        }

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.userTrackingMode = mapTrackingMode(from: trackingMode)
        // Calculate the region that fits the entire route
        if !route.isEmpty {
            let routeCoordinates = route.map { $0.coordinate }
            var routeRect = MKMapRect.null
            for coordinate in routeCoordinates {
                let point = MKMapPoint(coordinate)
                routeRect = routeRect.union(MKMapRect(x: point.x, y: point.y, width: 0, height: 0))
            }

            // Add padding to the routeRect
            let padding = 500.0 // Adjust this value as needed for more or less padding
            routeRect = routeRect.insetBy(dx: -padding, dy: -padding)

            let region = MKCoordinateRegion(routeRect)
            uiView.setRegion(region, animated: true)
        } else if let currentLocation = currentLocation {
            // If route is empty, focus on current location
            let region = MKCoordinateRegion(center: currentLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            uiView.setRegion(region, animated: true)
        }

        // Remove previous overlays
        uiView.removeOverlays(uiView.overlays)

        // Add polyline overlay for the route
        let polyline = MKPolyline(coordinates: route.map { $0.coordinate }, count: route.count)
        uiView.addOverlay(polyline)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        var isUserInitiatedChange = false

        init(_ parent: MapView) {
            self.parent = parent
        }

        @objc func handleGestureState(_ gestureRecognizer: UIGestureRecognizer) {
            if gestureRecognizer.state == .began {
                isUserInitiatedChange = true
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)

                // Get the accent color from UserDefaults
                if let colorData = UserDefaults.standard.data(forKey: "accentColor"),
                   let codableColor = try? JSONDecoder().decode(CodableColor.self, from: colorData) {
                    renderer.strokeColor = UIColor(red: CGFloat(codableColor.red),
                                                  green: CGFloat(codableColor.green),
                                                  blue: CGFloat(codableColor.blue),
                                                  alpha: CGFloat(codableColor.opacity))
                } else {
                    renderer.strokeColor = .systemBlue // Fallback
                }

                renderer.lineWidth = 4.0
                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            // We now detect gestures via the gesture recognizer target action
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if isUserInitiatedChange {
                // Reset tracking mode to 0 (.none) when user moves the map
                DispatchQueue.main.async {
                    self.parent.trackingMode = 0

                    // If we have a reference to the view model, update it directly too
                    if let viewModel = self.parent.viewModel {
                        viewModel.trackingMode = 0
                    }
                }
                isUserInitiatedChange = false
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
  @State var deepLink: String?
  ContentView(deepLink: $deepLink)
    .preferredColorScheme(.dark)
}
