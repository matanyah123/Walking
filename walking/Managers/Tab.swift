//
//  Tab.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 26/05/2025.
//
import SwiftUI
import WidgetKit

enum Tab {
    case home, walk, settings
}

// MARK: - Content View Model (Updated to Singleton)
class ContentViewModel: ObservableObject {
    static let shared = ContentViewModel()

    @Published var selectedTab: Tab = .home
    @Published var isStatsBarOpen = false
    @Published var offset: CGFloat = 0
    @Published var tracking = false
    @Published var started = false
    @Published var goal: Double? {
        didSet {
            if let goal = goal {
                UserDefaults.shared.set(goal, forKey: SharedKeys.currentGoalOverride)
            } else {
                UserDefaults.shared.removeObject(forKey: SharedKeys.currentGoalOverride)
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @Published var isKeyboardVisible = false
    @Published var trackingMode: Int = 0
    @Published var deepLink: String? {
        didSet {
            handleDeepLink()
        }
    }

    @AppStorage("doYouNeedAGoal") var doYouNeedAGoal: Bool = false
    @AppStorage(SharedKeys.currentGoalOverride, store: .shared)
    var goalTarget: Int = 5000

    private init() {
        // Load the session override if it exists
        let override = UserDefaults.shared.object(forKey: SharedKeys.currentGoalOverride) as? Double
        self.goal = override
    }

    private func handleDeepLink() {
        if deepLink == "start" {
            deepLinkStart()
        }
    }

    func deepLinkStart() {
        // This should trigger the same logic as your deep link handling
        deepLink = "start"
    }
}

extension ContentViewModel {
    func checkForWidgetStartRequest() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.matanyah.WalkTracker")
        if sharedDefaults?.bool(forKey: "shouldStartWalking") == true {
            sharedDefaults?.set(false, forKey: "shouldStartWalking")
            deepLinkStart()
        }
    }
}
