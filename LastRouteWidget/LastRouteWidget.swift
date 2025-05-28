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
    let route = (entry.walk?.route ?? []).map {
        CLLocation(latitude: $0.latitude, longitude: $0.longitude)
    }
    ZStack {
      if (widgetFamily == .systemSmall || widgetFamily == .systemMedium || widgetFamily == .systemLarge || widgetFamily == .systemExtraLarge) {
        LinearGradient(
          gradient: Gradient(colors: [Color.green.opacity(0.8), Color.orange.opacity(0.6)]),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        ).colorInvert()
        if (widgetFamily != .systemSmall) {
          Canvas { context, size in
            let path = createPath(from: route, in: size)
            context.stroke(
              path,
              with: .color(.white.opacity(0.85)),
              style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
          }
          .aspectRatio(1, contentMode: .fit)
          .padding(16)
        }
      }

      switch widgetFamily {
      case .systemMedium:
        HStack {
          mainWalkInfo
          Spacer()
        }
        .padding(16)

      case .systemLarge:
        HStack(alignment: .top){
          VStack(alignment: .leading) {
            mainWalkInfo
            Spacer()
          }
          Spacer()
        }
        .padding(16)

      case .accessoryInline:
        HStack{
          Image(systemName: "shoeprints.fill").padding(5)
          smallWalkInfo
        }
      case .accessoryCircular:
        VStack{
          circularWalkInfo
        }
      case .accessoryRectangular:
        HStack{
          rectangularWalkInfo
        }.padding()
      default:
        mainWalkInfo
          .padding(16)
      }
    }
    .padding(-17)
    .widgetURL(URL(string: "walktracker://open"))
    .containerBackground(.clear, for: .widget)
  }

  private var smallWalkInfo: some View {
    return ZStack() {
      if let walk = entry.walk {
        Text(" \(walk.distance >= 1000 ? String(format: "%.1f KM", walk.distance / 1000) : String(format: "%.0f M", walk.distance))")
      } else {
        Text("No recent walks")
          .font(.headline)
          .foregroundColor(.white)
          .fontWeight(.medium)
      }
    }
  }

  private var circularWalkInfo: some View {
    return VStack(alignment: .center) {
      if let walk = entry.walk {
        Text("Last walk")
          .font(.footnote)
          Text(" \(walk.distance >= 1000 ? String(format: "%.1f KM", walk.distance / 1000) : String(format: "%.0f M", walk.distance))")
          .font(.subheadline)
            .fontWeight(.bold)
        if let date = Calendar.current.date(byAdding: .day, value: 0, to: walk.date) {
          Text(date, style: .date)
            .font(.system(size: 10))
        }
      } else {
        Text("No recent walks")
          .font(.headline)
          .foregroundColor(.white)
          .fontWeight(.medium)
      }
    }
  }


  private var rectangularWalkInfo: some View {
    let route: [CLLocation] = (entry.walk?.route ?? []).map {
      CLLocation(latitude: $0.latitude, longitude: $0.longitude)
    }
    return VStack(alignment: .leading) {
      if let walk = entry.walk {
        HStack{
          Text("Last Walk:")
            .font(.footnote)
            .fontWeight(.bold)
          if let date = Calendar.current.date(byAdding: .day, value: 0, to: walk.date) {
            Text(date, style: .date)
              .font(.system(size: 10))
              .foregroundColor(.white.opacity(0.8))
          }
        }

        HStack{
          Canvas { context, size in
            let path = createPath(from: route, in: size)
            context.stroke(
              path,
              with: .color(.white.opacity(0.85)),
              style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
          }
          .frame(width: 10, height: 10)
          Text(" \(walk.distance >= 1000 ? String(format: "%.1f KM", walk.distance / 1000) : String(format: "%.0f M", walk.distance))")
            .font(.footnote)
            .foregroundColor(.white)
            .fontWeight(.bold)

          Text("\(Image(systemName: "clock")) \(formatDuration(timeInterval: walk.duration))")
            .font(.footnote)
            .fontWeight(.bold)
            .foregroundColor(.white.opacity(0.9))
        }
        .frame(height: 10)
      } else {
        Text("No recent walks")
          .font(.footnote)
          .foregroundColor(.white)
          .fontWeight(.medium)
      }
    }
  }

  private var mainWalkInfo: some View {
    let route: [CLLocation] = (entry.walk?.route ?? []).map {
      CLLocation(latitude: $0.latitude, longitude: $0.longitude)
    }
    return VStack(alignment: .leading, spacing: 4) {
      if let walk = entry.walk {
        Text("Last Walk")
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.white)
          .padding(.bottom, 2)

        if widgetFamily != .systemSmall {
          Text("\(Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")) \(walk.distance >= 1000 ? String(format: "%.1f KM", walk.distance / 1000) : String(format: "%.0f M", walk.distance))")
            .font(.body)
            .foregroundColor(.white)
            .fontWeight(.bold)
        } else {
          HStack{
            Canvas { context, size in
              let path = createPath(from: route, in: size)
              context.stroke(
                path,
                with: .color(.white.opacity(0.85)),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
              )
            }
            .frame(width: 10)
            Text(" \(walk.distance >= 1000 ? String(format: "%.1f KM", walk.distance / 1000) : String(format: "%.0f M", walk.distance))")
              .font(.body)
              .foregroundColor(.white)
              .fontWeight(.bold)
          }
          .frame(height: 15 )
        }

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

func createPath(from locations: [CLLocation], in size: CGSize) -> Path {
    guard locations.count > 1 else { return Path() }

    // Extract latitude and longitude values
    let latitudes = locations.map { $0.coordinate.latitude }
    let longitudes = locations.map { $0.coordinate.longitude }

    guard let minLat = latitudes.min(),
          let maxLat = latitudes.max(),
          let minLon = longitudes.min(),
          let maxLon = longitudes.max() else {
        return Path()
    }

    // Convert degrees to meters using approximate conversion:
    // 1 degree latitude ≈ 111,000 meters
    // longitude scaling depends on latitude (cosine)
    let midLat = (minLat + maxLat) / 2.0
    let latMeters = (maxLat - minLat) * 111_000
    let lonMeters = (maxLon - minLon) * 111_000 * cos(midLat * .pi / 180)

    // Calculate scale factor to fit path inside the size, preserving aspect ratio
    let scaleX = size.width / CGFloat(lonMeters)
    let scaleY = size.height / CGFloat(latMeters)
    let scale = min(scaleX, scaleY)

    // Calculate offsets to center the path inside the canvas
    let offsetX = (size.width - CGFloat(lonMeters) * scale) / 2
    let offsetY = (size.height - CGFloat(latMeters) * scale) / 2

    func convert(_ location: CLLocation) -> CGPoint {
        let xMeters = (location.coordinate.longitude - minLon) * 111_000 * cos(midLat * .pi / 180)
        let yMeters = (location.coordinate.latitude - minLat) * 111_000
        // y inverted because SwiftUI origin is top-left, latitude grows north (up)
        return CGPoint(
            x: offsetX + CGFloat(xMeters) * scale,
            y: size.height - (offsetY + CGFloat(yMeters) * scale)
        )
    }

    var path = Path()
    path.move(to: convert(locations[0]))
    for location in locations.dropFirst() {
        path.addLine(to: convert(location))
    }

    return path
}

struct LastRouteWidget_Previews: PreviewProvider {
    static var previews: some View {
      /*
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
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .preferredColorScheme(.dark)
       */
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
      .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
      .preferredColorScheme(.dark)
    }
}
