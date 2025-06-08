//
//  WalkSelectionIntent.swift
//  LastRouteWidget
//
//  Created by ‏מתניה ‏אליהו on 06/06/2025.
//

import AppIntents
import WidgetKit
import Foundation

struct WalkSelectionIntent: WidgetConfigurationIntent {
  static var title: LocalizedStringResource = "Select Walk"
  static var description = IntentDescription("Choose which walk to display in the widget.")

  @Parameter(title: "Walk")
  var selectedWalk: WalkOption?

  init() {
    self.selectedWalk = WalkOption.lastWalk
  }

  init(selectedWalk: WalkOption?) {
    self.selectedWalk = selectedWalk ?? WalkOption.lastWalk
  }
}

struct WalkOption: AppEntity, Identifiable, Hashable {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Walk"

  let id: String
  let displayString: String
  let walkData: WalkData?
  let walkDate: Date?

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(displayString)")
  }

  static let lastWalk = WalkOption(
    id: "last_walk",
    displayString: "Last Walk",
    walkData: nil,
    walkDate: nil
  )

  init(id: String, displayString: String, walkData: WalkData?, walkDate: Date? = nil) {
    self.id = id
    self.displayString = displayString
    self.walkData = walkData
    self.walkDate = walkDate
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: WalkOption, rhs: WalkOption) -> Bool {
    lhs.id == rhs.id
  }

  static var defaultQuery = WalkOptionsQuery()
}

struct WalkOptionsQuery: EntityQuery {
  func entities(for identifiers: [WalkOption.ID]) async throws -> [WalkOption] {
    await MainActor.run {
      let container = SharedDataContainer.shared
      let walks = container.fetchRecentWalks(limit: 20)

      var options = [WalkOption.lastWalk]

      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short

      for (index, walk) in walks.enumerated() {
        let walkId = "walk_\(walk.date.timeIntervalSince1970)_\(index)"
        let displayString = createDisplayString(for: walk, with: formatter)
        let option = WalkOption(
          id: walkId,
          displayString: displayString,
          walkData: walk,
          walkDate: walk.date
        )
        options.append(option)
      }

      return options.filter { identifiers.contains($0.id) }
    }
  }

  func suggestedEntities() async throws -> [WalkOption] {
    await MainActor.run {
      let container = SharedDataContainer.shared
      let walks = container.fetchRecentWalks(limit: 10)

      var options = [WalkOption.lastWalk]

      let formatter = DateFormatter()
      formatter.dateStyle = .short
      formatter.timeStyle = .short

      for (index, walk) in walks.enumerated() {
        let walkId = "walk_\(walk.date.timeIntervalSince1970)_\(index)"
        let displayString = createDisplayString(for: walk, with: formatter)
        let option = WalkOption(
          id: walkId,
          displayString: displayString,
          walkData: walk,
          walkDate: walk.date
        )
        options.append(option)
      }

      return options
    }
  }

  func defaultResult() async -> WalkOption? {
    return WalkOption.lastWalk
  }

  private func createDisplayString(for walk: WalkData, with formatter: DateFormatter) -> String {
    // If the walk has a custom name, use it as the primary identifier
    if let name = walk.name, !name.isEmpty {
      return "\(name) - \(formatter.string(from: walk.date)) - \(formatDistance(walk.distance))"
    } else {
      // Fallback to the original format if no name
      return "\(formatter.string(from: walk.date)) - \(formatDistance(walk.distance))"
    }
  }

  private func formatDistance(_ distance: Double) -> String {
    if distance >= 1000 {
      return String(format: "%.1f km", distance / 1000)
    } else {
      return String(format: "%.0f m", distance)
    }
  }
}
