//
//  LastRouteWidgetControl.swift
//  LastRouteWidget
//
//  Created by ‏מתניה ‏אליהו on 15/05/2025.
//
import SwiftUI
import WidgetKit
import AppIntents

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
	static var title: LocalizedStringResource = "Start Walking"

	func perform() async throws -> some IntentResult {
		// Request choice inside the perform function
		if #available(iOS 26.0, *) {
			let choice = try await requestChoice(between: Self.choices, dialog: .init("Select Latte Size")).title
			print("User selected: \(choice)")
		} else {
			print("Requested walk start")
		}

		return .result()
	}

	@available(iOS 26.0, *)
	static var choices: [IntentChoiceOption] {
		return [
			IntentChoiceOption(title: "small"),
			IntentChoiceOption(title: "medium"),
			IntentChoiceOption(title: "large")
		]
	}
}
