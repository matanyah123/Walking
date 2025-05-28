import SwiftUI
import WidgetKit
import CoreLocation
import MapKit
import UIKit
import Combine

enum Tab {
    case home, walk, settings
}

class ContentViewModel: ObservableObject {
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

  init() {
    // Load the session override if it exists, otherwise fall back to default
    let override = UserDefaults.shared.object(forKey: SharedKeys.currentGoalOverride) as? Double
    self.goal = override
  }
  @Published var isKeyboardVisible = false
  @Published var trackingMode: Int = 0

  @AppStorage("doYouNeedAGoal") var doYouNeedAGoal: Bool = false
  @AppStorage("mapStyleDarkMode", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var mapStyleDarkMode: Bool = true
  @AppStorage(SharedKeys.currentGoalOverride, store: .shared)
  var goalTarget: Int = 5000
}

struct ContentView: View {
  @Binding var deepLink: String?
  @StateObject private var viewModel = ContentViewModel()
  @StateObject private var locationManager = LocationManager()
  @StateObject private var motionManager = MotionManager()
  @StateObject var liveActivityManager = LiveActivityManager()

  var progress: Double {
    guard let goal = viewModel.goal, goal > 0 else { return 0 }
    return locationManager.distance / goal
  }

  @State private var height: CGFloat = 80.0


  var body: some View {
    ZStack(alignment: .bottom) {
      // Main content
      Group {
        mainTabView()
      }
      CustomBottomBar(
        started: $viewModel.started,
        tracking: $viewModel.tracking,
        doYouNeedAGoal: $viewModel.doYouNeedAGoal,
        goal: $viewModel.goal,
        goalTarget: viewModel.goalTarget,
        selectedTab: $viewModel.selectedTab,
        locationManager: locationManager,
        motionManager: motionManager,
        liveActivityManager: liveActivityManager,
        trackingMode: $viewModel.trackingMode,
        deepLink: $deepLink
      )
      .offset(y: viewModel.offset - 8.5)
    }
    .ignoresSafeArea(.container)

    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
      if !viewModel.isKeyboardVisible {
        viewModel.isKeyboardVisible = true

        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
          withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.offset = -keyboardFrame.height/20 + 8.5
          }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
          UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
      }
    }

    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
      if viewModel.isKeyboardVisible {
        viewModel.isKeyboardVisible = false

        withAnimation(.easeInOut(duration: 0.25)) {
          viewModel.offset = 0
        }

        // Haptic feedback after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
          UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
      }
    }
  }

  @ViewBuilder
  private func mainTabView() -> some View {
    ZStack{
      switch viewModel.selectedTab {
      case .home:
        homeTabView()
      case .walk:
        WalkHistoryView()
      case .settings:
        SettingsView(doYouNeedAGoal: $viewModel.doYouNeedAGoal)
      }
    }
    EdgeBlur(direction: .bottom, opacity: height/100).frame(height: height).transition(.opacity)
      .padding(.horizontal, -5)
  }

  @ViewBuilder
  private func homeTabView() -> some View {
    ZStack {
      MapView(route: locationManager.route,
              currentLocation: locationManager.currentLocation,
              showUserLocation: true, trackingMode: $viewModel.trackingMode)
      .colorScheme(viewModel.mapStyleDarkMode ? .dark : .light)
      .ignoresSafeArea()
      .onTapGesture {

        UIApplication.shared.dismissKeyboard()
        withAnimation(.easeIn(duration: 0.09)) {
          viewModel.isStatsBarOpen = false
        }
      }

      VStack {
        HStack {
          StatsBarView(
            isStatsBarOpen: $viewModel.isStatsBarOpen,
            started: $viewModel.started, tracking: $viewModel.tracking,
            goal: viewModel.goal,
            locationManager: locationManager,
            motionManager: motionManager
          )
            .padding(.top, 30)
          .onTapGesture {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
              UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }
            withAnimation(.easeOut(duration: 0.09)) {
              viewModel.isStatsBarOpen.toggle()
            }
          }

          if !viewModel.isStatsBarOpen {
            Spacer()
          }
        }
        Spacer()
      }
      .padding()
    }

  }

  private func clearData() {
    UserDefaults.standard.removeObject(forKey: "walkHistory")
  }
}



// MARK: - Preview

#Preview {
  @Previewable @State var deepLink: String?
  ContentView(deepLink: $deepLink)
    .preferredColorScheme(.dark)
}

// MARK: - Extensions

extension UIApplication {
  func dismissKeyboard() {
    sendAction(#selector(resignFirstResponder), to: nil, from: nil, for: nil)
  }
}
