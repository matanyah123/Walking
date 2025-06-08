//
//  LastRouteWidgetBundle.swift
//  LastRouteWidget
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//

import WidgetKit
import SwiftUI

@main
struct MyWidgetBundle: WidgetBundle {
  @WidgetBundleBuilder
  var body: some Widget {
    LastRouteWidget()
    LastRouteWidgetLiveActivity()
    //LastRouteWidgetControl()
  }
}

struct LastRouteWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: "LastRouteWidget", intent: WalkSelectionIntent.self, provider: WalkProvider()) { entry in
      LastRouteWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Last Walk")
    .description("Shows a snapshot of your most recent walk or a selected walk.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryInline, .accessoryCircular, .accessoryRectangular])
  }
}
