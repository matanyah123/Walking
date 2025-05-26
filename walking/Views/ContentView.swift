import SwiftUI
import WidgetKit
import CoreLocation
import MapKit
import UIKit
import Combine

// MARK: - Updated ContentView
struct ContentView: View {
    @Binding var deepLink: String?
    @StateObject private var sessionManager = WalkSessionManager.shared

    // Use the shared instances from the session manager
  private var viewModel: ContentViewModel { sessionManager.contentViewModel }
    private var locationManager: LocationManager { sessionManager.locationManager }
    private var motionManager: MotionManager { sessionManager.motionManager }
    private var liveActivityManager: LiveActivityManager { sessionManager.liveActivityManager }

    var progress: Double {
        guard let goal = viewModel.goal, goal > 0 else { return 0 }
        return locationManager.distance / goal
    }


  var body: some View {
    ZStack(alignment: .bottom) {
      Group {
        mainTabView()
      }

      CustomBottomBar(
          started: $sessionManager.contentViewModel.started,
          tracking: $sessionManager.contentViewModel.tracking,
          doYouNeedAGoal: $sessionManager.contentViewModel.doYouNeedAGoal,
          goal: $sessionManager.contentViewModel.goal,
          goalTarget: sessionManager.contentViewModel.goalTarget,
          selectedTab: $sessionManager.contentViewModel.selectedTab,
          trackingMode: $sessionManager.contentViewModel.trackingMode,
          deepLink: $deepLink
      )
      .padding(.bottom, 8)
      .offset(y: viewModel.offset)
    }

    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
      if !viewModel.isKeyboardVisible {
        viewModel.isKeyboardVisible = true

        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
          withAnimation(.easeInOut(duration: 0.25)) {
            viewModel.offset = -keyboardFrame.height/20
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
    switch viewModel.selectedTab {
    case .home:
      homeTabView()
    case .walk:
      WalkHistoryView()
    case .settings:
      SettingsView(doYouNeedAGoal: $sessionManager.contentViewModel.doYouNeedAGoal)
    }
  }

  @ViewBuilder
  private func homeTabView() -> some View {
    ZStack {
      MapView(route: locationManager.route,
              currentLocation: locationManager.currentLocation,
              showUserLocation: true, trackingMode: $sessionManager.contentViewModel.trackingMode)
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
              isStatsBarOpen: $sessionManager.contentViewModel.isStatsBarOpen,
              started: $sessionManager.contentViewModel.started,
              tracking: $sessionManager.contentViewModel.tracking,
              goal: sessionManager.contentViewModel.goal,
              locationManager: locationManager,
              motionManager: motionManager
          )
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
