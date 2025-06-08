//
//  StatsBarView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import SwiftUI

struct StatsBarView: View {
  @Binding var isStatsBarOpen: Bool
  @Binding var started: Bool
  @Binding var tracking: Bool
  var goal: Double?
  @ObservedObject var locationManager: LocationManager
  @ObservedObject var motionManager: MotionManager
  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var unit: Bool = true
  var body: some View {
    ZStack {
      BlurView(style: .systemUltraThinMaterialDark)
        .cornerRadius(10)
        .innerShadow(radius: 10)
        .frame(width: isStatsBarOpen ? .infinity : 75.0,
               height: isStatsBarOpen ? 275.0 : 75.0)
        .overlay {
          if isStatsBarOpen {
            expandedView
          } else {
            collapsedView
          }
        }
    }
  }

  private var collapsedView: some View {
    VStack {
      if locationManager.isTracking {
        // Show current walk stats when actively tracking
        VStack(spacing: 4) {
          Image(systemName: "shoeprints.fill")
            .font(.headline)
            .foregroundColor(.white)

          let distanceValue = unit ? locationManager.distance : locationManager.distance * 3.28084
          let unitLabel = unit ? "m" : "ft"
          Text("\(String(format: "%.2f", distanceValue)) \(unitLabel)")
            .font(.caption2)
            .bold()

          // Optional: Show tracking status
          Text("Tracking...")
            .font(.caption2)
            .opacity(0.7)
        }
      } else {
        // Default state - no active or paused walk
        Text("Good to\nsee you!")
          .font(.subheadline)
          .opacity(0.75)
          .multilineTextAlignment(.center)
      }
    }
  }

  private var expandedView: some View {
    Group {
      if started {
        VStack(alignment: .leading) {
          Text("Walk details").font(.title2).bold()
          Divider().frame(width: 110)
            .background(Color.white)

          StatLabel("Steps", value: "\(motionManager.stepCount)")

          // Speed conversion: km/h <-> mph
          let speedInKmH = locationManager.maxSpeed * 3.6
          let speedValue = unit ? speedInKmH : speedInKmH * 0.621371
          StatLabel("Max Speed", value: "\(String(format: "%.2f", speedValue)) \(unit ? "km/h" : "mph")")

          // Distance conversion: meters <-> feet
          let distanceValue = unit ? locationManager.distance : locationManager.distance * 3.28084
          StatLabel("Distance", value: "\(String(format: "%.2f", distanceValue)) \(unit ? "meters" : "feet")")

          // Elevation Gain conversion
          let elevationGainValue = unit ? locationManager.elevationGain : locationManager.elevationGain * 3.28084
          StatLabel("Elevation Gain", value: "\(String(format: "%.2f", elevationGainValue)) \(unit ? "meters" : "feet")")

          // Elevation Loss conversion
          let elevationLossValue = unit ? locationManager.elevationLoss : locationManager.elevationLoss * 3.28084
          StatLabel("Elevation Loss", value: "\(String(format: "%.2f", elevationLossValue)) \(unit ? "meters" : "feet")")

          if let goal = goal {
            let goalValue = unit ? goal : goal * 3.28084
            let progressValue = min(distanceValue / goalValue, 1.0)
            ProgressView("Progress", value: progressValue)
              .frame(width: 300.0)
              .font(.body)
              .bold()
          }
        }
      } else {
        Text("""
        To start a track, tap the \(Image(systemName: "figure.run")) icon in the bottom right corner.
        
        If you want to set a goal, tap the text field and type in your goal distance.
        
        On finish, or if you want to not set a goal, tap the \(Image(systemName: "checkmark")) icon and the track will start.
        """)
        .opacity(0.75)
        .font(.title3)
        .bold()
        .padding()
      }
    }
  }

  @ViewBuilder
  private func StatLabel(_ label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("\(label): \(value)")
        .font(.headline)
      Divider().frame(width: 300)
        .background(Color.white)
    }
  }
}

#Preview("Open - Dummy Track Active") {
  @Previewable @State var started: Bool = false
  ZStack{
    BlurView(style: .systemThinMaterialDark).ignoresSafeArea(.all)
    StatsBarView(
      isStatsBarOpen: .constant(true),
      started: .constant(true), tracking: $started,
      goal: 1000.0,
      locationManager: {
        let manager = LocationManager()
        manager.distance = 750
        manager.maxSpeed = 5.2
        manager.elevationGain = 12
        manager.elevationLoss = 8
        return manager
      }(),
      motionManager: {
        let motion = MotionManager()
        motion.stepCount = 1520
        return motion
      }()
    )
  }.preferredColorScheme(.dark)
}

#Preview("Closed - Dummy Track Active") {
  @Previewable @State var started: Bool = false
  ZStack{
    BlurView(style: .systemThinMaterialDark).ignoresSafeArea(.all)
    StatsBarView(
      isStatsBarOpen: .constant(false),
      started: .constant(true), tracking: $started,
      goal: 1000.0,
      locationManager: {
        let manager = LocationManager()
        manager.distance = 750
        manager.maxSpeed = 5.2
        manager.elevationGain = 12
        manager.elevationLoss = 8
        return manager
      }(),
      motionManager: {
        let motion = MotionManager()
        motion.stepCount = 1520
        return motion
      }()
    )
  }.preferredColorScheme(.dark)
}
