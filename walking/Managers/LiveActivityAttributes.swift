//
//  LiveActivityAttributes.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 20/05/2024.
//

@preconcurrency import ActivityKit
import SwiftUI

struct LastRouteWidgetAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var distance: Double
    var steps: Int
  }

  var name: String
  var accentColor: CodableColor
  var currentGoalOverride: Double
  var unit: Bool
}


class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    @Published var currentActivity: Activity<LastRouteWidgetAttributes>? = nil

  func startLiveActivity() async {
    let colorData = UserDefaults.shared.data(forKey: "accentColor")
    let accent = (try? JSONDecoder().decode(CodableColor.self, from: colorData ?? Data())) ?? CodableColor(red: 0, green: 0, blue: 1, opacity: 1)

    let goal = UserDefaults.shared.double(forKey: SharedKeys.currentGoalOverride)  // read goal here
    let unit = UserDefaults.shared.object(forKey: SharedKeys.unit) as? Bool ?? true  // read unit here

    let attributes = LastRouteWidgetAttributes(name: "Matanyah's Walk", accentColor: accent, currentGoalOverride: goal, unit: unit) // pass goal

    let initialState = LastRouteWidgetAttributes.ContentState(distance: 0, steps: 0)

    do {
      let activity = try Activity<LastRouteWidgetAttributes>.request(
        attributes: attributes,
        contentState: initialState,
        pushType: nil
      )
      print("✅ Live Activity started: \(activity.id)")
      DispatchQueue.main.async {
        self.currentActivity = activity
      }
    } catch {
      print("❌ Failed to start Live Activity: \(error)")
    }
  }

    func updateLiveActivity(distance: Double, steps: Int) async {
        guard let activity = currentActivity else { return }

        let updatedState = LastRouteWidgetAttributes.ContentState(distance: distance, steps: steps)
        await activity.update(using: updatedState)
    }

    func endLiveActivity() async {
        guard let activity = currentActivity else { return }

        let finalState = LastRouteWidgetAttributes.ContentState(distance: 0, steps: 0)
        await activity.end(using: finalState, dismissalPolicy: .immediate)

        DispatchQueue.main.async {
            self.currentActivity = nil
        }
    }
}

enum SharedKeys {
  static let goalTarget = "goalTarget"               // Default goal set in settings
  static let currentGoalOverride = "currentGoal"     // Temporary session goal
  static let unit = "unit"                    // unit
}

extension UserDefaults {
  static let shared = UserDefaults(suiteName: "group.com.matanyah.WalkTracker")!
}

