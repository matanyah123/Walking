//
//  MotionManager.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 20/05/2024.
//
import CoreMotion

class MotionManager: ObservableObject {
  static var shared = MotionManager()
  @Published var stepCount: Int = 0
  private var pedometer = CMPedometer()
  private var startDate: Date?
  
  func startTracking() {
    startDate = Date()
    saveStartTime()
    
    if CMPedometer.isStepCountingAvailable() {
      pedometer.startUpdates(from: startDate!) { [weak self] data, error in
        guard let data = data, error == nil else { return }
        DispatchQueue.main.async {
          self?.stepCount = data.numberOfSteps.intValue
        }
      }
    }
  }
  
  func resumeTracking() {
    guard let savedStart = loadStartTime() else { return }
    startDate = savedStart
    
    if CMPedometer.isStepCountingAvailable() {
      // Get historical data from saved start time to now
      pedometer.queryPedometerData(from: savedStart, to: Date()) { [weak self] data, error in
        guard let data = data, error == nil else { return }
        DispatchQueue.main.async {
          self?.stepCount = data.numberOfSteps.intValue
        }
      }
      
      // Then start live updates from savedStart
      pedometer.startUpdates(from: savedStart) { [weak self] data, error in
        guard let data = data, error == nil else { return }
        DispatchQueue.main.async {
          self?.stepCount = data.numberOfSteps.intValue
        }
      }
    }
  }
  
  func stopTracking() {
    pedometer.stopUpdates()
  }
  
  func clearData() {
    stepCount = 0
    startDate = nil
    UserDefaults.standard.removeObject(forKey: "motionStartDate")
  }
  
  private func saveStartTime() {
    if let startDate = startDate {
      UserDefaults.standard.set(startDate.timeIntervalSince1970, forKey: "motionStartDate")
    }
  }
  
  private func loadStartTime() -> Date? {
    let time = UserDefaults.standard.double(forKey: "motionStartDate")
    return time > 0 ? Date(timeIntervalSince1970: time) : nil
  }
}
