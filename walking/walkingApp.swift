//
//  walkingApp.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 20/05/2024.
//

import SwiftUI
import Combine
import ActivityKit
import SwiftData

@main
struct walkingApp: App {
  @StateObject private var appTheme = AppTheme()
  @State var deepLink: String?
  var body: some Scene {
    WindowGroup {
      ContentView(deepLink: $deepLink)
        .environmentObject(appTheme)
        .tint(appTheme.accentColor)
        .onOpenURL { url in
          if url.scheme == "walking", url.host == "start" {            deepLink = "group.com.matanyah.walking.start"
          }
        }
    }.modelContainer(for: WalkData.self)
  }
}

#Preview {
  @Previewable @State var deepLink: String? = "start"
  ContentView(deepLink: $deepLink)
    .preferredColorScheme(.dark)
}

class AppTheme: ObservableObject {
  @Published var accentColor: Color = .accentFromSettings
    private var cancellables = Set<AnyCancellable>()

    init() {
        loadColor()

        // Monitor for changes in UserDefaults
        NotificationCenter.default
            .publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                self?.loadColor()
            }
            .store(in: &cancellables)
    }

  private func loadColor() {
      let data = UserDefaults(suiteName: "group.com.matanyah.WalkTracker")?.data(forKey: "accentColor") ?? Data()
      let color = (try? JSONDecoder().decode(CodableColor.self, from: data))?.color ?? .blue

      DispatchQueue.main.async { [weak self] in
          self?.accentColor = color
      }
  }
}
