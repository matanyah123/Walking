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
  var body: some View {
    ZStack {
      BlurView(style: .systemUltraThinMaterialDark)
        .cornerRadius(10)
        .innerShadow(radius: 10)
        .frame(width: isStatsBarOpen ? 382.5 : 75.0,
               height: isStatsBarOpen ? 275.0 : 75.0)
        .overlay {
          if isStatsBarOpen {
            expandedView
          } else {
            collapsedView
          }
        }
    }
    .contextMenu {
      Text("View current walk data")
    }
  }

  private var collapsedView: some View {
    VStack {
      if locationManager.hasSavedWalk {
          Button(action: resumePreviousWalk) {
              Text("🚶 Resume Previous Walk")
                  .font(.headline)
                  .padding()
                  .background(Color.green.opacity(0.8))
                  .foregroundColor(.white)
                  .cornerRadius(12)
          }
      } else {
        if started {
          VStack(spacing: 4) {
            Image(systemName: "shoeprints.fill")
              .font(.headline)
              .foregroundColor(.white)

            Text("\(String(format: "%.2f", locationManager.distance)) M")
              .font(.caption2)
              .bold()
          }
        } else {
          Text("Good to\nsee you!")
            .font(.subheadline)
            .opacity(0.75)
            .multilineTextAlignment(.center)
        }
      }
    }
    .onAppear {
      locationManager.checkSavedState()
    }
  }

  func resumePreviousWalk() {
      locationManager.loadState()
      motionManager.resumeTracking()
      locationManager.startTracking()
      tracking = true
      started = true
  }

  private var expandedView: some View {
    Group {
      if started {
        VStack(alignment: .leading) {
          Text("Walk details").font(.title2).bold()
          Divider().frame(width: 110)
            .background(Color.white)
          StatLabel("Steps", value: "\(motionManager.stepCount)")
          StatLabel("Max Speed", value: "\(String(format: "%.2f", locationManager.maxSpeed)) km/h")
          StatLabel("Distance", value: "\(String(format: "%.2f", locationManager.distance)) meters")
          StatLabel("Elevation Gain", value: "\(String(format: "%.2f", locationManager.elevationGain)) meters")
          StatLabel("Elevation Loss", value: "\(String(format: "%.2f", locationManager.elevationLoss)) meters")

          if let goal = goal {
            ProgressView("Progress", value: min(locationManager.distance / goal, 1.0))
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

/*
#Preview("Open - Dummy Track Active") {
  ZStack{
    BlurView(style: .systemThinMaterialDark).ignoresSafeArea(.all)
    StatsBarView(
      isStatsBarOpen: .constant(true),
      started: .constant(true), tracking: <#Binding<Bool>#>,
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
  ZStack{
    BlurView(style: .systemThinMaterialDark).ignoresSafeArea(.all)
    StatsBarView(
        isStatsBarOpen: .constant(false),
        started: .constant(true),
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

#Preview("Open - No Track") {
  ZStack{
    BlurView(style: .systemThinMaterialDark).ignoresSafeArea(.all)
    StatsBarView(
        isStatsBarOpen: .constant(true),
        started: .constant(false),
        goal: nil,
        locationManager: LocationManager(),
        motionManager: MotionManager()
    )
  }.preferredColorScheme(.dark)
}

#Preview("Closed - No Track") {
  ZStack{
    BlurView(style: .systemThinMaterialDark).ignoresSafeArea(.all)
    StatsBarView(
        isStatsBarOpen: .constant(false),
        started: .constant(false),
        goal: nil,
        locationManager: LocationManager(),
        motionManager: MotionManager()
    )
  }.preferredColorScheme(.dark)
}
*/
