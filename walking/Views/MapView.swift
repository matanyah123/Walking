//
//  MapView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 28/05/2025.
//
import SwiftUI
import MapKit
import Photos

private func mapTrackingMode(from intValue: Int) -> MKUserTrackingMode {
    switch intValue {
    case 1: return .follow
    case 2: return .followWithHeading
    default: return .none
    }
}

// Custom annotation class for images
class ImageAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let walkImage: WalkImage
    let title: String?

    init(coordinate: CLLocationCoordinate2D, walkImage: WalkImage, title: String? = nil) {
        self.coordinate = coordinate
        self.walkImage = walkImage
        self.title = title
        super.init()
    }
}

struct MapView: UIViewRepresentable {
    var route: [CLLocation]
    var currentLocation: CLLocation?
    var showUserLocation: Bool
    @Binding var trackingMode: Int
    var viewModel: ContentViewModel?
    var showImages: Bool = false
    var images: [WalkImage] = []

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

        // Remove previous overlays and annotations
        uiView.removeOverlays(uiView.overlays)
        uiView.removeAnnotations(uiView.annotations.filter { !($0 is MKUserLocation) })

        // Add polyline overlay for the route
        let polyline = MKPolyline(coordinates: route.map { $0.coordinate }, count: route.count)
        uiView.addOverlay(polyline)

        // Add image annotations if requested
        if showImages {
            context.coordinator.addImageAnnotations(to: uiView, images: images)
        }
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

        func addImageAnnotations(to mapView: MKMapView, images: [WalkImage]) {
            print("Adding \(images.count) image annotations to map")

            for (index, image) in images.enumerated() {
                // Extract location from image metadata
                extractLocationFromImage(image) { [weak self] coordinate in
                    guard let coordinate = coordinate else {
                        print("No location found for image \(index)")
                        return
                    }

                    print("Found location for image \(index): \(coordinate)")
                    DispatchQueue.main.async {
                        let annotation = ImageAnnotation(
                            coordinate: coordinate,
                            walkImage: image,
                            title: nil
                        )
                        mapView.addAnnotation(annotation)
                    }
                }
            }
        }

        private func extractLocationFromImage(_ walkImage: WalkImage, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
            guard let localIdentifier = walkImage.localIdentifier else {
                print("No local identifier for walk image")
                completion(nil)
                return
            }

            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = assets.firstObject else {
                print("No asset found for identifier: \(localIdentifier)")
                completion(nil)
                return
            }

            // First try to get location directly from PHAsset
            if let location = asset.location {
                print("Found location from PHAsset: \(location.coordinate)")
                completion(location.coordinate)
                return
            }

            // If no location in PHAsset, try to extract from EXIF data
            print("No location in PHAsset, trying EXIF data extraction")
            extractLocationFromEXIF(asset: asset, completion: completion)
        }

        private func extractLocationFromEXIF(asset: PHAsset, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false

            PHImageManager.default().requestImageData(for: asset, options: options) { data, _, _, _ in
                guard let data = data,
                      let source = CGImageSourceCreateWithData(data as CFData, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
                      let gpsInfo = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
                    print("No GPS data found in EXIF")
                    completion(nil)
                    return
                }

                print("Found GPS data in EXIF: \(gpsInfo)")

                guard let latitude = gpsInfo[kCGImagePropertyGPSLatitude as String] as? Double,
                      let longitude = gpsInfo[kCGImagePropertyGPSLongitude as String] as? Double,
                      let latitudeRef = gpsInfo[kCGImagePropertyGPSLatitudeRef as String] as? String,
                      let longitudeRef = gpsInfo[kCGImagePropertyGPSLongitudeRef as String] as? String else {
                    print("Invalid GPS coordinates in EXIF")
                    completion(nil)
                    return
                }

                let finalLatitude = latitudeRef == "S" ? -latitude : latitude
                let finalLongitude = longitudeRef == "W" ? -longitude : longitude

                let coordinate = CLLocationCoordinate2D(latitude: finalLatitude, longitude: finalLongitude)
                print("Extracted coordinates from EXIF: \(coordinate)")
                completion(coordinate)
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

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Handle user location annotation
            if annotation is MKUserLocation {
                return nil
            }

            // Handle image annotations
            if let imageAnnotation = annotation as? ImageAnnotation {
                let identifier = "ImageAnnotation"
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)

                if annotationView == nil {
                    annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                    annotationView?.canShowCallout = true
                    annotationView?.calloutOffset = CGPoint(x: 0, y: -5)

                    // Make the annotation view larger and more visible
                    annotationView?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
                } else {
                    annotationView?.annotation = annotation
                }

                // Create custom callout view with image
                let calloutView = createCalloutView(for: imageAnnotation)
                annotationView?.detailCalloutAccessoryView = calloutView

                // Create a camera icon for the annotation
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                imageView.backgroundColor = UIColor.systemBlue
                imageView.layer.cornerRadius = 20
                imageView.layer.borderWidth = 3
                imageView.layer.borderColor = UIColor.white.cgColor
                imageView.layer.shadowColor = UIColor.black.cgColor
                imageView.layer.shadowOffset = CGSize(width: 0, height: 2)
                imageView.layer.shadowOpacity = 0.3
                imageView.layer.shadowRadius = 3

                // Add camera symbol
                let cameraImage = UIImage(systemName: "camera.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                imageView.image = cameraImage
                imageView.contentMode = .center

                // Clear previous subviews and add the new one
                annotationView?.subviews.forEach { $0.removeFromSuperview() }
                annotationView?.addSubview(imageView)

                return annotationView
            }

            return nil
        }

        private func createCalloutView(for imageAnnotation: ImageAnnotation) -> UIView {
          let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 450))

          let imageView = UIImageView(frame: CGRect(x: 10, y: 10, width: 580, height: 430))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.backgroundColor = UIColor.systemGray5

            // Add loading indicator
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.center = imageView.center
            activityIndicator.startAnimating()
            imageView.addSubview(activityIndicator)

            containerView.addSubview(imageView)

            // Load the actual image
            loadImageForCallout(imageAnnotation.walkImage) { image in
                DispatchQueue.main.async {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()

                    if let image = image {
                        imageView.image = image
                    } else {
                        // Show placeholder if image loading fails
                        let placeholderImage = UIImage(systemName: "photo")?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
                        imageView.image = placeholderImage
                        imageView.contentMode = .center
                    }
                }
            }

            return containerView
        }

        private func loadImageForCallout(_ walkImage: WalkImage, completion: @escaping (UIImage?) -> Void) {
            guard let localIdentifier = walkImage.localIdentifier else {
                completion(nil)
                return
            }

            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
            guard let asset = assets.firstObject else {
                completion(nil)
                return
            }

            let imageManager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast

            imageManager.requestImage(for: asset,
                                      targetSize: CGSize(width: 1080, height: 780), // 2x resolution for better quality
                                      contentMode: .aspectFill,
                                      options: options) { image, _ in
                completion(image)
            }
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
    WalkDetailView(walk: WalkData.dummy)
}
