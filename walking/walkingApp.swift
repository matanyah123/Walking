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
  @StateObject private var liveActions = LiveActions.shared

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(appTheme)
        .tint(appTheme.accentColor)
        .onOpenURL { url in
            switch url.host {
            case "toggleWalk":
              liveActions.toggleWalk.toggle()
            case "openCamera":
              liveActions.openCamera = true
            case "startWalk":
              liveActions.startWalk = true
            default:
                break
            }
        }
    }.modelContainer(SharedDataContainer.shared.container)
  }
}

#Preview {
  ContentView()
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
