//
//  LastRouteWidgetControl.swift
//  LastRouteWidget
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//

import AppIntents
import SwiftUI
import WidgetKit

struct LastRouteWidgetControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    StaticControlConfiguration(
      kind: "-01.walking.LastRouteWidget",
      provider: Provider()
    ) {
      ControlWidgetButton(
        "Start Walking",
        action: StartWalkingIntent()
      ) {_ in
        Label("Start", systemImage: "figure.walk")
      }
    }
    .displayName("Walking")
    .description("Start walking tracking.")
  }
}

extension LastRouteWidgetControl {
  struct Provider: ControlValueProvider {
    var previewValue: Void {}

    func currentValue() async throws -> Void {
      // No state needed for a button
      return ()
    }
  }
}

struct StartWalkingIntent: AppIntent {
  static let title: LocalizedStringResource = "Start Walking"

  func perform() async throws -> some IntentResult {
    WalkSessionManager.shared.start()
    print("Walk started!")
    return .result()
  }
}
