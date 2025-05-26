//
//  LastRouteWidget.swift
//  LastRouteWidget
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//

import WidgetKit
import SwiftUI
import Intents
import CoreLocation

struct WalkEntry: TimelineEntry {
    let date: Date
    let walk: WalkData?
  let goalTarget: Int
}

struct WalkProvider: TimelineProvider {
    func placeholder(in context: Context) -> WalkEntry {
      WalkEntry(date: Date(), walk: nil, goalTarget: 5000)
    }

    func getSnapshot(in context: Context, completion: @escaping (WalkEntry) -> ()) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WalkEntry>) -> ()) {
        let entry = loadEntry()
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
        completion(timeline)
    }

  private func loadEntry() -> WalkEntry {
      guard let sharedDefaults = UserDefaults(suiteName: "group.com.matanyah.WalkTracker") else {
          return WalkEntry(date: Date(), walk: nil, goalTarget: 5000)
      }

      let walk = loadLatestWalk(from: sharedDefaults)
      let goal = fetchGoalTarget() // 👈 this line is what was missing!
      return WalkEntry(date: Date(), walk: walk, goalTarget: goal)
  }

    private func loadLatestWalk(from sharedDefaults: UserDefaults) -> WalkData? {
        guard let data = sharedDefaults.data(forKey: "latestWalk"),
              let walk = try? JSONDecoder().decode(WalkData.self, from: data) else {
            return nil
        }
        return walk
    }
  private func fetchGoalTarget() -> Int {
    let defaults = UserDefaults(suiteName: "group.com.matanyah.WalkTracker")
    let override = defaults?.object(forKey: SharedKeys.currentGoalOverride) as? Double
    return Int(override ?? Double(defaults?.integer(forKey: SharedKeys.goalTarget) ?? 5000))
  }
}

struct LastRouteWidgetEntryView: View {
  var entry: WalkEntry
  @Environment(\.widgetFamily) var widgetFamily

  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [Color.green.opacity(0.8), Color.orange.opacity(0.6)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      ).colorInvert()

      switch widgetFamily {
      case .systemMedium:
        HStack {
          mainWalkInfo
          Spacer()
          VStack {
            Image(systemName: "figure.walk")
              .font(.largeTitle)
              .bold()
          }
          .padding(.trailing, 12)
        }
        .padding(16)

      case .systemLarge:
        VStack(alignment: .leading, spacing: 8) {
          mainWalkInfo
          Spacer()
          HStack {
            Spacer()
            VStack(alignment: .trailing) {
              Image(systemName: "figure.run")
                .font(.largeTitle)
                .bold()
            }
          }
        }
        .padding(16)

      default:
        mainWalkInfo
          .padding(16)
      }
    }
    .padding(-17)
    .widgetURL(URL(string: "walktracker://open"))
    .containerBackground(.clear, for: .widget)
  }

  private var mainWalkInfo: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let walk = entry.walk {
        Text("Last Walk")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.bottom, 2)

        Text("\(Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")) \(walk.distance >= 1000 ? String(format: "%.1f KM", walk.distance / 1000) : String(format: "%.0f M", walk.distance))")
          .font(.body)
          .foregroundColor(.white)
          .fontWeight(.bold)

        Text("\(Image(systemName: "shoeprints.fill")) \(walk.steps)")
          .font(.callout)
          .fontWeight(.bold)
          .foregroundColor(.white.opacity(0.9))

        Text("\(Image(systemName: "clock")) \(formatDuration(timeInterval: walk.duration))")
          .font(.callout)
          .fontWeight(.bold)
          .foregroundColor(.white.opacity(0.9))

        if let date = Calendar.current.date(byAdding: .day, value: 0, to: walk.date) {
          Text(date, style: .date)
            .font(.caption)
            .foregroundColor(.white.opacity(0.8))
            .padding(.top, 2)
        }
      } else {
        Text("No recent walks")
          .font(.headline)
          .foregroundColor(.white)
          .fontWeight(.medium)
      }
    }
  }

  func formatDuration(timeInterval: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .abbreviated
    formatter.allowedUnits = timeInterval >= 3600 ? [.hour, .minute] : [.minute, .second]
    return formatter.string(from: timeInterval) ?? "0m"
  }
}

struct LastRouteWidget_Previews: PreviewProvider {
    static var previews: some View {
        LastRouteWidgetEntryView(entry: WalkEntry(
            date: Date(),
            walk: WalkData(
                date: Date(),
                startTime: Date().addingTimeInterval(-33676),
                endTime: Date(),
                steps: 16789,
                distance: 10560.4,
                maxSpeed: 2.5,
                elevationGain: 12.3,
                elevationLoss: 10.1,
                route: [
                    CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137),
                    CLLocationCoordinate2D(latitude: 31.7690, longitude: 35.2145)
                ]
            ), goalTarget: 5000
        ))
        .previewContext(WidgetPreviewContext(family: .systemLarge))
        .preferredColorScheme(.dark)
    }
}
