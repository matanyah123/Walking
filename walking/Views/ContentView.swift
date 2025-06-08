//
//  ContentView.swift
//  walking
//
//  Created by ‏מתניה ‏אליהו on 14/05/2025.
//
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
  static let shared = ContentViewModel()
  @Published var isKeyboardVisible = false
  @Published var selectedDetent: PresentationDetent = .medium
  @Published var selectedTab: Tab = .home
  @Published var isStatsBarOpen = false
  @Published var trackingMode: Int = 0
  @Published var isCameraOpen = false
  @Published var offset: CGFloat = 0
  @Published var tracking = false
  @Published var started = false
  @Published var isLastOneGlows = false
  @Published var isSearchActive = false
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
  @Published var isPaymentWallShown: Bool = false

  init() {
    // Load the session override if it exists, otherwise fall back to default
    let override = UserDefaults.shared.object(forKey: SharedKeys.currentGoalOverride) as? Double
    self.goal = override
  }

  @AppStorage("doYouNeedAGoal") var doYouNeedAGoal: Bool = false
  @AppStorage("darkMode", store: UserDefaults(suiteName: "group.com.matanyah.WalkTracker")) var darkMode: Bool = true

  @AppStorage(SharedKeys.currentGoalOverride, store: .shared)var goalTarget: Int = 5000
}

struct ContentView: View {
  //@Environment(\.modelContext) private var modelContext
  @Binding var deepLink: String?
  @StateObject private var viewModel = ContentViewModel.shared
  @StateObject private var locationManager = LocationManager()
  @StateObject private var motionManager = MotionManager()
  @StateObject var liveActivityManager = LiveActivityManager()
  @StateObject private var cameraModel = CameraModel()

  var progress: Double {
    guard let goal = viewModel.goal, goal > 0 else { return 0 }
    return locationManager.distance / goal
  }

  @State private var height: CGFloat = 80.0


  var body: some View {
    ZStack(alignment: .bottom) {
      Group {
        mainTabView()
      }
      EdgeBlur(direction: .bottom, opacity: height/75).frame(height: height).transition(.opacity)
      CustomBottomBar(
        started: $viewModel.started,
        tracking: $viewModel.tracking,
        doYouNeedAGoal: $viewModel.doYouNeedAGoal,
        goal: $viewModel.goal,
        goalTarget: viewModel.goalTarget, isSearchActive: $viewModel.isSearchActive,
        selectedTab: $viewModel.selectedTab,
        locationManager: locationManager,
        motionManager: motionManager,
        liveActivityManager: liveActivityManager, cameraModel: cameraModel,
        trackingMode: $viewModel.trackingMode,
        deepLink: $deepLink
      )
      .padding(.bottom)
      InAppBanner()
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
    .onAppear {
      // MARK: - viewModel.isPaymentWallShown = true
      WidgetCenter.shared.reloadAllTimelines()
    }
    .sheet(isPresented: $viewModel.isPaymentWallShown){
      PaymentWall()
    }
  }

  @ViewBuilder
  private func mainTabView() -> some View {
    ZStack{
      switch viewModel.selectedTab {
      case .home:
        homeTabView()
      case .walk:
        WalkActivityView(isLastOneGlows: $viewModel.isLastOneGlows)
          .colorScheme(viewModel.darkMode ? .dark : .light)
      case .settings:
        SettingsView(doYouNeedAGoal: $viewModel.doYouNeedAGoal)
          .colorScheme(viewModel.darkMode ? .dark : .light)
      }
    }
  }

  @ViewBuilder
  private func homeTabView() -> some View {
    ZStack {
      MapView(route: locationManager.route,
              currentLocation: locationManager.currentLocation,
              showUserLocation: true, trackingMode: $viewModel.trackingMode)
      .colorScheme(viewModel.darkMode ? .dark : .light)
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
          .padding(.top, 40)
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
        if viewModel.tracking {
          HStack{
            Button{
              withAnimation(.easeInOut(duration: 0.09)) {
                viewModel.isCameraOpen.toggle()
              }
            }label: {
              Image(systemName: "camera.fill")
                .foregroundColor(.white)
                .padding()
                .background(BlurView(style: .systemUltraThinMaterialDark).cornerRadius(10).innerShadow(radius: 10))
            }
            Spacer()
          }
          .padding(.top)
        }
        Spacer()
      }
      .sheet(isPresented: $viewModel.isCameraOpen) {
        CameraView(
          cameraModel: cameraModel,
          darkMode: viewModel.darkMode,
          selectedDetent: $viewModel.selectedDetent
        )
        .presentationDetents(cameraModel.capturedPhotos.isEmpty ? [.medium] : [.medium ,.large], selection: $viewModel.selectedDetent)
        .presentationDragIndicator(cameraModel.capturedPhotos.isEmpty ? .hidden : .visible)
      }
      .onChange(of: viewModel.started) { _, newValue in
        if newValue {
          // Clear photos when starting a new walk
          cameraModel.clearPhotos()
        }
      }
      .padding()
    }
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
