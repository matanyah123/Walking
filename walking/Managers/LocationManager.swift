//
//  LocationManager.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 20/05/2024.
//
import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager = CLLocationManager()
  @Published var route: [CLLocation] = []
  @Published var currentLocation: CLLocation?
  @Published var distance: Double = 0
  @Published var maxSpeed: Double = 0
  @Published var elevationGain: Double = 0
  @Published var elevationLoss: Double = 0
  @Published var hasSavedWalk: Bool = false
  @Published var isTracking: Bool = false
  @Published var isPaused: Bool = false

  private var previousLocation: CLLocation?
  private var totalElevationGain: Double = 0
  private var totalElevationLoss: Double = 0
  @Published var startTime: Date?
  @Published var endTime: Date?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = false

    // Check for any saved walk on startup
    checkSavedState()
  }

  func startTracking() {
    locationManager.startUpdatingLocation()
    locationManager.startMonitoringSignificantLocationChanges()
    startTime = Date()
    isTracking = true
    isPaused = false
    hasSavedWalk = false
    print("🚀 Started tracking")
  }

  func pauseTracking() {
    guard isTracking && !isPaused else { return }

    saveState()
    isPaused = true
    hasSavedWalk = true
    locationManager.stopUpdatingLocation() // stop the high-accuracy updates
    locationManager.startMonitoringSignificantLocationChanges() // low-power alternative
    print("⏸️ Tracking paused and state saved")
  }

  func resumeTracking() {
    guard isPaused else { return }

    loadState()
    isPaused = false
    hasSavedWalk = false
    isTracking = true
    locationManager.stopMonitoringSignificantLocationChanges()
    locationManager.startUpdatingLocation()
    print("▶️ Tracking resumed from saved state")
  }

  func stopTracking() {
    isPaused = false
    isTracking = false
    hasSavedWalk = false
    locationManager.stopUpdatingLocation()
    locationManager.stopMonitoringSignificantLocationChanges()
    endTime = Date()

    // Here you would typically save the completed walk to permanent storage
    // saveCompletedWalk()

    clearSavedState()
    print("⏹️ Tracking stopped and walk completed")
  }

  func cancelTracking() {
    isPaused = false
    isTracking = false
    hasSavedWalk = false
    locationManager.stopUpdatingLocation()
    locationManager.stopMonitoringSignificantLocationChanges()

    clearSavedState()
    clearData()
    print("❌ Tracking cancelled")
  }

  func saveState() {
    // Save route data
    let encodedRoute = route.map { [$0.coordinate.latitude, $0.coordinate.longitude, $0.altitude, $0.timestamp.timeIntervalSince1970] }
    UserDefaults.standard.set(encodedRoute, forKey: "savedRoute")

    // Save distance and speed data
    UserDefaults.standard.set(distance, forKey: "savedDistance")
    UserDefaults.standard.set(maxSpeed, forKey: "savedMaxSpeed")

    // Save elevation data
    UserDefaults.standard.set(elevationGain, forKey: "savedElevationGain")
    UserDefaults.standard.set(elevationLoss, forKey: "savedElevationLoss")
    UserDefaults.standard.set(totalElevationGain, forKey: "savedTotalElevationGain")
    UserDefaults.standard.set(totalElevationLoss, forKey: "savedTotalElevationLoss")

    // Save time data
    if let startTime = startTime {
      UserDefaults.standard.set(startTime.timeIntervalSince1970, forKey: "savedStartTime")
    }

    // Save current location if available
    if let currentLocation = currentLocation {
      let encodedCurrentLocation = [currentLocation.coordinate.latitude, currentLocation.coordinate.longitude, currentLocation.altitude, currentLocation.timestamp.timeIntervalSince1970]
      UserDefaults.standard.set(encodedCurrentLocation, forKey: "savedCurrentLocation")
    }

    // Mark that we have a saved walk
    UserDefaults.standard.set(true, forKey: "hasSavedWalk")

    print("💾 State saved successfully")
  }

  func loadState() {
    // Load route data
    if let savedRoute = UserDefaults.standard.array(forKey: "savedRoute") as? [[Double]] {
      self.route = savedRoute.map {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]),
                   altitude: $0[2], horizontalAccuracy: 1, verticalAccuracy: 1,
                   timestamp: Date(timeIntervalSince1970: $0[3]))
      }
    }

    // Load distance and speed data
    self.distance = UserDefaults.standard.double(forKey: "savedDistance")
    self.maxSpeed = UserDefaults.standard.double(forKey: "savedMaxSpeed")

    // Load elevation data
    self.elevationGain = UserDefaults.standard.double(forKey: "savedElevationGain")
    self.elevationLoss = UserDefaults.standard.double(forKey: "savedElevationLoss")
    self.totalElevationGain = UserDefaults.standard.double(forKey: "savedTotalElevationGain")
    self.totalElevationLoss = UserDefaults.standard.double(forKey: "savedTotalElevationLoss")

    // Load time data
    let savedStartTimeInterval = UserDefaults.standard.double(forKey: "savedStartTime")
    if savedStartTimeInterval > 0 {
      self.startTime = Date(timeIntervalSince1970: savedStartTimeInterval)
    }

    // Load current location
    if let savedCurrentLocationArray = UserDefaults.standard.array(forKey: "savedCurrentLocation") as? [Double],
       savedCurrentLocationArray.count == 4 {
      self.currentLocation = CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: savedCurrentLocationArray[0], longitude: savedCurrentLocationArray[1]),
        altitude: savedCurrentLocationArray[2],
        horizontalAccuracy: 1,
        verticalAccuracy: 1,
        timestamp: Date(timeIntervalSince1970: savedCurrentLocationArray[3])
      )
    }

    print("📂 State loaded successfully")
  }

  func clearSavedState() {
    let keys = [
      "savedRoute", "savedDistance", "savedMaxSpeed", "savedElevationGain",
      "savedElevationLoss", "savedTotalElevationGain", "savedTotalElevationLoss",
      "savedStartTime", "savedCurrentLocation", "hasSavedWalk"
    ]
    keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    print("🧼 Saved state cleared.")
  }

  func clearData() {
    route = []
    distance = 0
    maxSpeed = 0
    elevationGain = 0
    elevationLoss = 0
    totalElevationGain = 0
    totalElevationLoss = 0
    startTime = nil
    endTime = nil
    currentLocation = nil
    previousLocation = nil
  }

  func clearRoute() {
    route = []
  }

  public func checkSavedState() {
    let savedWalkExists = UserDefaults.standard.bool(forKey: "hasSavedWalk")
    hasSavedWalk = savedWalkExists

    if savedWalkExists {
      isPaused = true
      isTracking = false
      print("📱 Found saved walk on app launch")
    }
  }

  // MARK: - CLLocationManagerDelegate

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for location in locations {
      guard location.horizontalAccuracy < 20 else { continue }

      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        if let lastLocation = self.route.last {
          let distanceDelta = location.distance(from: lastLocation)
          self.distance += distanceDelta

          let elevationDelta = location.altitude - lastLocation.altitude
          if elevationDelta > 0 {
            self.totalElevationGain += elevationDelta
            self.elevationGain = self.totalElevationGain
          } else {
            self.totalElevationLoss -= elevationDelta
            self.elevationLoss = self.totalElevationLoss
          }

          let speed = location.speed
          if speed > self.maxSpeed {
            self.maxSpeed = speed
          }
        }

        self.route.append(location)
        self.currentLocation = location
        self.previousLocation = location
      }
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("❌ Location manager failed with error: \(error.localizedDescription)")
  }

  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .notDetermined:
      print("📍 Location authorization not determined")
    case .denied, .restricted:
      print("❌ Location access denied or restricted")
    case .authorizedWhenInUse:
      print("📍 Location authorized when in use")
    case .authorizedAlways:
      print("✅ Location always authorized")
    @unknown default:
      print("📍 Unknown location authorization status")
    }
  }
}
