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
  let configuration: WalkSelectionIntent
}

@MainActor
struct WalkProvider: @preconcurrency AppIntentTimelineProvider {
  typealias Entry = WalkEntry
  typealias Intent = WalkSelectionIntent

  func placeholder(in context: Context) -> WalkEntry {
    WalkEntry(date: Date(), walk: nil, goalTarget: 5000, configuration: WalkSelectionIntent())
  }

  func snapshot(for configuration: WalkSelectionIntent, in context: Context) async -> WalkEntry {
    return loadEntry(for: configuration)
  }

  func timeline(for configuration: WalkSelectionIntent, in context: Context) async -> Timeline<WalkEntry> {
    let entry = loadEntry(for: configuration)
    return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300)))
  }

  private func loadEntry(for configuration: WalkSelectionIntent) -> WalkEntry {
    let walk = loadWalk(for: configuration)
    let goal = fetchGoalTarget()
    return WalkEntry(date: Date(), walk: walk, goalTarget: goal, configuration: configuration)
  }

  private func loadWalk(for configuration: WalkSelectionIntent) -> WalkData? {
    let container = SharedDataContainer.shared

    // If "Last Walk" is selected or no specific walk is configured
    if let selectedWalk = configuration.selectedWalk,
       selectedWalk.id != "last_walk",
       let walkData = selectedWalk.walkData {
      return walkData
    } else {
      // Return the most recent walk
      return container.fetchRecentWalks(limit: 1).first
    }
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
  @Environment(\.widgetRenderingMode) private var renderingMode
  @Environment(\.colorScheme) private var colorScheme

  @AppStorage("unit", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var unit: Bool = true
  @AppStorage("isPlusUser", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) private var isPlusUser: Bool = false

	var body: some View {
		if isPlusUser {
			let route = (entry.walk?.route ?? []).map {
				CLLocation(latitude: $0.latitude, longitude: $0.longitude)
			}
			ZStack {
				let Route = Canvas { context, size in
					let path = createPath(from: route, in: size)
					context.stroke(
						path,
						with: .color((widgetFamily == .systemSmall ? .black.opacity(0.2) : .white.opacity(0.85))),
						style: StrokeStyle(lineWidth: (widgetFamily == .systemSmall ? 8 : 5), lineCap: .round, lineJoin: .round)
					)
				}
					.aspectRatio(1, contentMode: .fit)
					.padding(10)

				if (widgetFamily == .systemSmall || widgetFamily == .systemMedium || widgetFamily == .systemLarge || widgetFamily == .systemExtraLarge) {
					if renderingMode != .accented {
						LinearGradient(
							gradient: Gradient(colors: [Color.green.opacity(0.8), Color.orange.opacity(0.6)]),
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						).colorInvert()
					}
				}

				switch widgetFamily {
				case .systemMedium:
					HStack {
						mainWalkInfo.shadow(radius: 10)
						Spacer()
						Route.shadow(radius: 10)
						Spacer()
					}
					.padding(16)

				case .systemLarge:
					VStack(alignment: .leading, spacing: 16) {

						HStack(alignment: .top, spacing: 16) {
							mainWalkInfo.shadow(radius: 10)
							Spacer()
							Route.shadow(radius: 10)
							Spacer()
						}
						.frame(maxHeight: 135)

						Spacer(minLength: 24)

						HStack {
							Spacer()
							Text("Great Job!\nKeep walking")
								.font(.largeTitle.bold())
								.multilineTextAlignment(.center)
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
					ZStack{
						Route
						mainWalkInfo.shadow(radius: 10)
					}
					.padding(16)
				}
			}
			.padding(-20)
			.widgetURL(URL(string: "walktracker://open"))
			.containerBackground(.clear, for: .widget)
		} else {
			ZStack{
				if renderingMode != .accented {
					LinearGradient(
						gradient: Gradient(colors: [Color.green.opacity(0.8), Color.orange.opacity(0.6)]),
						startPoint: .topLeading,
						endPoint: .bottomTrailing
					).colorInvert().ignoresSafeArea(.all).padding(-17)
				}
				Text("You need to buy Walking Plus to nsee this widget")
					.tint(Color.primary)
			}
			.widgetURL(URL(string: "walktracker://open"))
			.containerBackground(.clear, for: .widget)
		}
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
        Text(walkTitle)
          .font(.system(size: 10, weight: .medium))
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .minimumScaleFactor(0.8)
        Text(" \(walk.distance >= 1000 ? String(format: "%.1f KM", walk.distance / 1000) : String(format: "%.0f M", walk.distance))")
          .font(.subheadline)
          .fontWeight(.bold)
        if let date = Calendar.current.date(byAdding: .day, value: 0, to: walk.date) {
          Text(date, style: .date)
            .font(.system(size: 9))
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
    return VStack(alignment: .leading, spacing: 2) {
      if let walk = entry.walk {
        HStack(alignment: .top){
          Text(walkTitle)
            .font(.system(size: 11, weight: .bold))
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .minimumScaleFactor(0.9)
            .frame(maxWidth: .infinity, alignment: .leading)

          if let date = Calendar.current.date(byAdding: .day, value: 0, to: walk.date) {
            Text(date, style: .date)
              .font(.system(size: 9))
              .foregroundColor(.white.opacity(0.8))
              .lineLimit(1)
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
          let distanceValue = unit
          ? (walk.distance >= 1000 ? walk.distance / 1000 : walk.distance)
          : (walk.distance >= 1609.34 ? walk.distance / 1609.34 : walk.distance * 3.28084)

          let unitLabel = unit
          ? (walk.distance >= 1000 ? "km" : "m")
          : (walk.distance >= 1609.34 ? "mi" : "ft")

          Text(String(format: distanceValue >= 10 ? "%.1f %@" : "%.0f %@", distanceValue, unitLabel))
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
        Text(walkTitle)
          .font(widgetFamily == .systemSmall ? .system(size: 16, weight: .bold) : .title3.bold())
          .foregroundColor(.white)
          .padding(.bottom, 2)
          .lineLimit(widgetFamily == .systemSmall ? 2 : 3)
          .multilineTextAlignment(.leading)
          .minimumScaleFactor(widgetFamily == .systemSmall ? 0.8 : 0.9)

        if widgetFamily != .systemSmall {
          Text("\(Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")) \(unit ? (walk.distance >= 1000 ? String(format: "%.1f km", walk.distance / 1000) : String(format: "%.0f m", walk.distance)) : (walk.distance >= 1609.34 ? String(format: "%.1f mi", walk.distance / 1609.34) : String(format: "%.0f ft", walk.distance * 3.28084)))")
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
            Text(" \(unit ? (walk.distance >= 1000 ? String(format: "%.1f km", walk.distance / 1000) : String(format: "%.0f m", walk.distance)) : (walk.distance >= 1609.34 ? String(format: "%.1f mi", walk.distance / 1609.34) : String(format: "%.0f ft", walk.distance * 3.28084)))")
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

  private var walkTitle: String {
    guard let walk = entry.walk else { return "No recent walks" }

    // If there's a custom name, use it
    if let name = walk.name, !name.isEmpty {
      return name
    }

    // Otherwise, use default titles based on configuration
    if let selectedWalk = entry.configuration.selectedWalk,
       selectedWalk.id != "last_walk" {
      return "Selected Walk"
    } else {
      return "Last Walk"
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
    LastRouteWidgetEntryView(entry: WalkEntry(
      date: Date(),
      walk: WalkData.dummy, goalTarget: 5000, configuration: WalkSelectionIntent()
    ))
    .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
