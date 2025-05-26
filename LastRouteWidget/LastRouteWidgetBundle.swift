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
    LastRouteWidgetControl()
  }
}

struct LastRouteWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LastRouteWidget", provider: WalkProvider()) { entry in
            LastRouteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Last Walk")
        .description("Shows a snapshot of your most recent walk.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
