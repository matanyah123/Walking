import ActivityKit
import WidgetKit
import SwiftUI
import ActivityKit



// MARK: - Live Activity Widget
struct LastRouteWidgetLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: LastRouteWidgetAttributes.self) { context in
      let goal = context.attributes.currentGoalOverride
      let progress = min(context.state.distance / goal, 1.0)
      let percentage = progress * 100

      HStack {
        VStack(alignment: .leading) {
          Text("You walked \(context.state.distance, specifier: "%.1f") meters and \(context.state.steps) steps")
            .font(.subheadline)
            .bold()
            .contentTransition(.numericText(value: context.state.distance))
            .foregroundStyle(Color.black.opacity(0.6))
          if goal > 0 {
          ProgressView("You completed \(percentage, specifier: "%.1f")% of your goal", value: progress)
            .contentTransition(.numericText(value: percentage))
            .font(.subheadline)
            .foregroundStyle(Color.black
              .opacity(0.6))
          }
        }

        Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
          .resizable()
          .scaledToFit()
          .frame(width: 40, height: (goal > 0) ? 40 : 30)
          .bold()
          .foregroundStyle(Color.black.opacity(0.6))
        Button{
          //.toggleTracking()
        }label:{
          Image(systemName: "pause.fill")
        }
      }
      .padding()
      .tint(Color.black.opacity(0.6))
      .activityBackgroundTint(Color.accentFromSettings.opacity(0.8))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "figure.walk")
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing) {
            Text("\(context.state.distance, specifier: "%.1f") m")
            Text("\(context.state.steps) steps")
          }
          .font(.caption2)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading) {
            Text("Distance: \(context.state.distance, specifier: "%.1f") m")
            Text("Steps: \(context.state.steps)")
          }
          .font(.footnote)
        }
      } compactLeading: {
        Image(systemName: "figure.walk")
      } compactTrailing: {
        Text("\(Int(context.state.distance))m")
      } minimal: {
        Text("shoeprints.fill")
      }
      .widgetURL(URL(string: "walktracker://live"))
      .keylineTint(Color.red)
    }
  }
}

// MARK: - Preview
extension LastRouteWidgetAttributes {
    fileprivate static var preview: LastRouteWidgetAttributes {
      LastRouteWidgetAttributes(name: "Matanyah's Walk", accentColor: .lavenderBlue, currentGoalOverride: 10)
    }
}

extension LastRouteWidgetAttributes.ContentState {
    fileprivate static var example: LastRouteWidgetAttributes.ContentState {
      LastRouteWidgetAttributes.ContentState(distance: 58.3, steps: 367)
    }
}

#Preview("Live Activity", as: .content, using: LastRouteWidgetAttributes.preview) {
    LastRouteWidgetLiveActivity()
} contentStates: {
  LastRouteWidgetAttributes.ContentState.example
}
