//LocationManager
import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  static let shared = LocationManager()
  private var locationManager: CLLocationManager = CLLocationManager()
  @Published var route: [CLLocation] = []
  @Published var currentLocation: CLLocation?
  @Published var distance: Double = 0
  @Published var maxSpeed: Double = 0
  @Published var elevationGain: Double = 0
  @Published var elevationLoss: Double = 0
  @Published var hasSavedWalk: Bool = false
  private var previousLocation: CLLocation?
  private var totalElevationGain: Double = 0
  private var totalElevationLoss: Double = 0
  @Published var startTime: Date?
  @Published var endTime: Date?
  private var isPaused = false
  
  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.requestAlwaysAuthorization()
    locationManager.allowsBackgroundLocationUpdates = true
    locationManager.pausesLocationUpdatesAutomatically = false
  }
  
  func startTracking() {
    locationManager.startUpdatingLocation()
    locationManager.startMonitoringSignificantLocationChanges()
    startTime = Date()
  }
  
  func pauseTracking() {
    saveState()
    isPaused = true
    locationManager.stopUpdatingLocation() // stop the high-accuracy updates
    locationManager.startMonitoringSignificantLocationChanges() // low-power alternative
  }
  
  func saveState() {
    let encodedRoute = route.map { [$0.coordinate.latitude, $0.coordinate.longitude, $0.altitude, $0.timestamp.timeIntervalSince1970] }
    UserDefaults.standard.set(encodedRoute, forKey: "savedRoute")
    UserDefaults.standard.set(distance, forKey: "savedDistance")
    // add more as needed
  }
  
  func resumeTracking() {
    loadState()
    isPaused = false
    locationManager.stopMonitoringSignificantLocationChanges()
    locationManager.startUpdatingLocation()
  }
  
  func loadState() {
    if let savedRoute = UserDefaults.standard.array(forKey: "savedRoute") as? [[Double]] {
      self.route = savedRoute.map {
        CLLocation(coordinate: CLLocationCoordinate2D(latitude: $0[0], longitude: $0[1]),
                   altitude: $0[2], horizontalAccuracy: 1, verticalAccuracy: 1,
                   timestamp: Date(timeIntervalSince1970: $0[3]))
      }
    }
    self.distance = UserDefaults.standard.double(forKey: "savedDistance")
    // etc
  }
  
  func stopTracking() {
    isPaused = false
    locationManager.stopUpdatingLocation()
    locationManager.stopMonitoringSignificantLocationChanges()
    endTime = Date()
    clearSavedState()
  }
  
  func clearSavedState() {
    let keys = [
      "savedRoute", "savedDistance", "savedMaxSpeed", "savedElevationGain",
      "savedElevationLoss", "savedTotalElevationGain", "savedTotalElevationLoss", "savedStartTime"
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
  }
  
  func clearRoute() {
    route = []
  }
  
  
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
      }
    }
  }
  public
  func checkSavedState() {
    let routeExists = UserDefaults.standard.array(forKey: "savedRoute") != nil
    hasSavedWalk = routeExists
  }
}
