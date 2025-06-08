//
//  LastRouteWidgetLiveActivity.swift
//  LastRouteWidget
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import ActivityKit
import WidgetKit
import SwiftUI
import ActivityKit



// MARK: - Live Activity Widget
struct LastRouteWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LastRouteWidgetAttributes.self) { context in
        let isWalkActive = context.state.isWalking // <-- bool from your activity content state

        let goal = context.attributes.currentGoalOverride
        let unit = context.attributes.unit

        let displayDistance = unit ? context.state.distance : context.state.distance * 3.28084
        let displayGoal = unit ? goal : goal * 3.28084
        let unitText = unit ? "meters" : "feet"
        let unitAbbr = unit ? "m" : "ft"

        let progress = displayGoal > 0 ? min(displayDistance / displayGoal, 1.0) : 0.0
        let percentage = progress * 100

        HStack {
            VStack(alignment: .leading) {
                Text("You walked \(displayDistance, specifier: "%.1f") \(unitText) and \(context.state.steps) steps")
                    .font(.subheadline)
                    .bold()
                    .contentTransition(.numericText(value: displayDistance))
                    .foregroundStyle(Color.black.opacity(0.6))

                if displayGoal > 0 {
                    ProgressView("You completed \(percentage, specifier: "%.1f")% of your goal", value: progress)
                        .contentTransition(.numericText(value: percentage))
                        .font(.subheadline)
                        .foregroundStyle(Color.black.opacity(0.6))
                }
            }

            Link(destination: URL(string: "walking://toggleWalk")!) {
                Image(systemName: isWalkActive ? "play.circle.fill" : "pause.circle.fill")
                .font(.title2)
                    .bold()
                    .foregroundStyle(Color.black.opacity(0.6))
            }

            Link(destination: URL(string: "walking://openCamera")!) {
                Image(systemName: "camera.circle.fill")
                .font(.title2)
                    .bold()
                    .foregroundStyle(Color.black.opacity(0.6))
            }
        }
        .padding()
        .tint(Color.black.opacity(0.6))
        .activityBackgroundTint(Color.accentFromSettings.opacity(0.8))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          let unit = context.attributes.unit
          let displayDistance = unit ? context.state.distance : context.state.distance * 3.28084
          let unitAbbr = unit ? "m" : "ft"

          HStack{
            Image(systemName: "figure.walk")
            Text("\(displayDistance, specifier: "%.1f") \(unitAbbr)")
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          HStack{
            Text("\(context.state.steps)")
            Image(systemName: "shoeprints.fill")
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          let unit = context.attributes.unit
          let displayDistance = unit ? context.state.distance : context.state.distance * 3.28084
          let unitText = unit ? "meters" : "feet"
          let goal = context.attributes.currentGoalOverride
          let displayGoal = unit ? goal : goal * 3.28084
          let progress = displayGoal > 0 ? min(displayDistance / displayGoal, 1.0) : 0.0
          let percentage = progress * 100

          VStack(alignment: .leading, spacing: 10.0) {
            Spacer().frame(height: 10)
            Text("You walked \(displayDistance, specifier: "%.1f") \(unitText) and \(context.state.steps) steps")
              .font(.subheadline)
              .bold()
              .contentTransition(.numericText(value: displayDistance))
            if displayGoal > 0 {
              ProgressView("You completed \(percentage, specifier: "%.1f")% of your goal", value: progress)
                .contentTransition(.numericText(value: percentage))
                .font(.title3)
                .foregroundStyle(Color.white)
                .tint(Color.white)
            }
          }
          .font(.footnote)
        }
      } compactLeading: {
        let unit = context.attributes.unit
        let goal = context.attributes.currentGoalOverride
        let displayDistance = unit ? context.state.distance : context.state.distance * 3.28084
        let displayGoal = unit ? goal : goal * 3.28084
        let progress = displayGoal > 0 ? min(displayDistance / displayGoal, 1.0) : 0.0
        let percentage = progress * 100

        ProgressView("\(percentage, specifier: "%.0f")",value: progress)
          .progressViewStyle(.circular)
          .bold()
          .frame(width: 25, height: 25)
          .padding(5)
      } compactTrailing: {
        Image(systemName: "figure.walk")
          .padding(.trailing)
      } minimal: {
        Image(systemName: "shoeprints.fill")
      }
      .widgetURL(URL(string: "walktracker://live"))
      .keylineTint(Color.red)
    }
  }
}

// MARK: - Preview
extension LastRouteWidgetAttributes {
  fileprivate static var preview: LastRouteWidgetAttributes {
    LastRouteWidgetAttributes(name: "Matanyah's Walk", accentColor: .lavenderBlue, currentGoalOverride: 10, unit: false)
  }
}

extension LastRouteWidgetAttributes.ContentState {
  fileprivate static var example: LastRouteWidgetAttributes.ContentState {
    LastRouteWidgetAttributes.ContentState(distance: 58.3, steps: 367, isWalking: true)
  }
}

#Preview("Live Activity", as: .content, using: LastRouteWidgetAttributes.preview) {
  LastRouteWidgetLiveActivity()
} contentStates: {
  LastRouteWidgetAttributes.ContentState.example
}

/*
struct LastRouteWidgetLiveActivity_Previews: PreviewProvider {
  static let attributes = LastRouteWidgetAttributes.preview
  static let contentState = LastRouteWidgetAttributes.ContentState.example
  static let goalCompletedState = LastRouteWidgetAttributes.ContentState.example
  
  static var previews: some View {
    Group {
      // Dynamic Island States
      attributes
        .previewContext(contentState, viewKind: .dynamicIsland(.compact))
        .previewDisplayName("DI Compact - In Progress")
      
      attributes
        .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
        .previewDisplayName("DI Expanded - In Progress")
      
      attributes
        .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
        .previewDisplayName("DI Minimal - In Progress")
      
      // Goal completed state
      attributes
        .previewContext(goalCompletedState, viewKind: .dynamicIsland(.expanded))
        .previewDisplayName("DI Expanded - Goal Completed")
    }
  }
}
*/
